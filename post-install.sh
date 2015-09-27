# --------------------------------------------------------------
#!/bin/bash
# Script d'installation automatique serveur LAMP + Moodle
#
#	Ecrit par Kenny CALVAT. Symetrix.
#	Version 1.0
#	Date : 10/06/2015
#
# --------------------------------------------------------------

# A FAIRE
# - Configurer memcached Moodle
# - Configurer iptables
# - Configurer apache selon protocole
# - Sécuriser accès opcachedgui
# - Sécuriser accès phpmemcached

# --------------------------------------------------------------
# Les variables
# --------------------------------------------------------------

# Les chemins
fichierSources='/etc/apt/sources.list'
fichierLog='log/postinstall.log'

# Gestion des paquets
paquets_ssh="openssh-client openssh-server "
paquets_editeur="nano vim git zsh "
paquet_gestion="ntpdate "
paquets_stats="htop nmon logwatch iotop "
paquets_apache="apache2-mpm-worker libapache2-mod-php5 libapache2-mod-fastcgi "
paquets_mysql="mysql-server mysql-client "
paquets_cache="memcached "
paquets_php="php5-mysqlnd php5-curl php5-xmlrpc php5-gd php5-intl php5-fpm php5-memcached "
paquets_email="ssmtp "
paquets_securite="fail2ban clamav rkhunter apticron unattended-upgrades "
liste_paquets="$paquets_ssh $paquets_editeur $paquet_gestion $paquets_stats $paquets_administration $paquets_apache $paquets_cache $paquets_php $paquets_mysql $paquets_email $paquets_securite"

# --------------------------------------------------------------
# Gestion de la couleur
# --------------------------------------------------------------

export black='\033[0m'
export boldblack='\033[1;0m'
export red='\033[31m'
export boldred='\033[1;31m'
export green='\033[32m'
export boldgreen='\033[1;32m'
export yellow='\033[33m'
export boldyellow='\033[1;33m'
export blue='\033[34m'
export boldblue='\033[1;34m'
export magenta='\033[35m'
export boldmagenta='\033[1;35m'
export cyan='\033[36m'
export boldcyan='\033[1;36m'
export white='\033[37m'
export boldwhite='\033[1;37m'

function cecho ()

## -- Function to easliy print colored text -- ##
	
	# Color-echo.
	# Argument $1 = message
	# Argument $2 = color
{
local default_msg="No message passed."

message=${1:-$default_msg}	# Defaults to default message.

#change it for fun
#We use pure names
color=${2:-black}		# Defaults to black, if not specified.

case $color in
	black)
		 printf "$black" ;;
	boldblack)
		 printf "$boldblack" ;;
	red)
		 printf "$red" ;;
	boldred)
		 printf "$boldred" ;;
	green)
		 printf "$green" ;;
	boldgreen)
		 printf "$boldgreen" ;;
	yellow)
		 printf "$yellow" ;;
	boldyellow)
		 printf "$boldyellow" ;;
	blue)
		 printf "$blue" ;;
	boldblue)
		 printf "$boldblue" ;;
	magenta)
		 printf "$magenta" ;;
	boldmagenta)
		 printf "$boldmagenta" ;;
	cyan)
		 printf "$cyan" ;;
	boldcyan)
		 printf "$boldcyan" ;;
	white)
		 printf "$white" ;;
	boldwhite)
		 printf "$boldwhite" ;;
esac
  printf "%s\n"  "$message"
  tput sgr0			# Reset to normal.
  printf "$black"

return
}

# --------------------------------------------------------------
# Début du script
# --------------------------------------------------------------

echo
cecho "---------------------------------------------------------" yellow
cecho "Installation automatique de Moodle" yellow
cecho "---------------------------------------------------------" yellow
echo

echo
cecho "Utilitaire de configuration" yellow
cecho "---------------------------------------------------------" yellow
echo

# Adresse email du demandeur
	echo -n "Entrer votre adresse e-mail (les informations de connexions vous seront envoyées) : "
	read email_demandeur

# URL du Moodle à installer
	echo -n "Entrer l'URL du Moodle : "
	read urldusite

# Choix du protocole HTTP
	echo "Quel protocole Souhaitez-vous utiliser ? "
	echo "  1. HTTP seul"
	echo "  2. HTTPS seul"
	echo "  3. Redirection HTTP vers HTTPS"
	echo "  4. HTTP et HTTPS"
	echo -n "Votre choix : "
	read choix_protocole
	echo

	case $choix_protocole in
		1)
			protocole='http'
		;;
		2)
			protocole='https'
		;;
		[34])
			protocole='http https'
		;;
	esac

	apt-get install -y pwgen > /dev/null

# Définition du compte
	compte_moodle=`echo $urldusite | cut -f1 -d.`
	compte_moodle_mdp=`pwgen -1`
	compte_db_moodle_mdp=`pwgen -1`
	compte_db_root_mdp=`pwgen -1`

# Définition du dossier racine moodle
	dossier_moodle_racine="/var/www/$compte_moodle"
	dossier_moodle_systeme="$dossier_moodle_racine/moodle"
    dossier_moodledata="$dossier_moodle_racine/moodledata"

# Affichage des variables à l'écran pour contrôle
	echo "Ceci va définir les variables de scripts suivants :"
	echo "- Email du demandeur : $email_demandeur"
	echo "- URL du vHost : $urldusite"
	echo "- Protocole utilisé : $protocole"
	echo "- Compte système Moodle : $compte_moodle"
	echo "- Mot de passe du compte système Moodle : $compte_moodle_mdp"
	echo "- Dossier d'installation racine : $dossier_moodle_racine"
	echo "- Dossier système Moodle : $dossier_moodle_systeme"
	echo "- Dossier data Moodle : $dossier_moodledata"
	echo "- Compte root base de données : root"
	echo "- Mot de passe du compte root base de données : $compte_db_root_mdp"
	echo "- Nom de la base de données : $compte_moodle"
	echo "- Utilisateur de la base de donnée : $compte_moodle"
	echo "- Mot de passe de l'utilisateur base de donnée : $compte_db_moodle_mdp"
	echo

# Confirmation des variables par l'utilisateur
	echo "Souhaitez-vous continuer ? [o/n] "
	read choix

	case $choix in
		![oO])
			exit 1
		;;
	esac

	echo
	cecho "Début de l'installation" yellow
	cecho "---------------------------------------------------------" yellow
	echo

# Sauvegarde le fichier courant des sources. Le numéro final le plus grand et le fichier le plus récent.
	if ! [ -f /etc/apt/sources.list.old.1 ] ; then
		cp $fichierSources /etc/apt/sources.list.old.1
	else
		numero=`ls /etc/apt/sources* | sort -r | head -1 | cut -d. -f4`
		numero=$(($numero + 1))

		cp $fichierSources /etc/apt/sources.list.old.$numero
	fi

# Modification du fichier des sources
	echo -n "- Modification du fichier sources.list : "
	if cat conf/sources.list > /etc/apt/sources.list ; then
		cecho "[OK]" green
	else
		cecho "[BAD]" red
	fi

# Mise à jour du système
	echo -n "- Mise à jour du Système : "
	if apt-get update > /dev/null && apt-get upgrade -y > /dev/null && apt-get check > /dev/null && apt-get autoclean > /dev/null && apt-get autoremove > /dev/null ; then
		cecho "[OK]" green
	else
		cecho "[BAD]" red
	fi

# Configuration de MySQL avant installation
	debconf-set-selections <<< "mysql-server mysql-server/root_password password $compte_db_root_mdp"
	debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $compte_db_root_mdp"

# Installation des paquets de base
	echo
	cecho "Installation des paquets :" yellow
	for paquet in $liste_paquets ; do
		echo -n "- $paquet : "
		if apt-get install -y $paquet > /dev/null ; then
			cecho "[OK]" green
		else
			cecho "[BAD]" red
		fi
	done
	
	echo
	cecho "Configuration des paquets :" yellow

# Configuration de VIM
	echo -n "- Configuration de VIM : "
	if cat conf/.vimrc > $HOME/.vimrc ; then
		cecho "[OK]" green
	else
		cecho "[BAD]" red
	fi

# Configuration de SSMTP
	echo -n "- Configuration de SSMTP : "
	if cat conf/ssmtp.conf > /etc/ssmtp/ssmtp.conf ; then
		cecho "[OK]" green
	else
		cecho "[BAD]" red
	fi

	hostname=`hostname`
	sed -i -e 's/nom_hote/'"$hostname"'/' /etc/ssmtp/ssmtp.conf

	echo -n "- Configuration de revaliases : "
	if cat conf/revaliases > /etc/ssmtp/revaliases ; then
		cecho "[OK]" green
	else
		cecho "[BAD]" red
	fi

# Test d'envoie d'e-mail
	echo `hostname` : Mail ok ! | mail -s "test d'envoi d'email depuis `hostname`" $email_demandeur

	echo
	cecho "Compte et arborescence Moodle :" yellow

# Configuration de apticron
	sed -i -e 's/EMAIL="root"/EMAIL="'"$email_demandeur"'"/' /etc/apticron/apticron.conf
	sed -i -e 's/# SYSTEM="foobar.example.com"/SYSTEM="'"$urldusite - `hostname`"'"/' /etc/apticron/apticron.conf

# Configuration de unattended-upgrade
	sed -i -e 's/Unattended-Upgrade::Mail "root";/Unattended-Upgrade::Mail "'"$email_demandeur"'";/' /etc/apt/apt.conf.d/50unattended-upgrades

# Création de l'utilisateur Moodle
	echo -n "- Création du compte $compte_moodle : "
	if useradd $compte_moodle ; then
		cecho "[OK]" green
		echo "$compte_moodle:$compte_moodle_mdp" | chpasswd
	else
		cecho "[BAD]" red
	fi

# Création de l'arborescence
	echo -n "- Création du dossier $dossier_moodle_systeme : "
	if ! [ -d $dossier_moodle_systeme ] ; then
		mkdir -p $dossier_moodle_systeme
		cecho "[OK]" green
	else
		cecho "[OK]" green
	fi
	
	echo -n "- Création du dossier $dossier_moodledata : "
	if ! [ -d $dossier_moodledata ] ; then
		mkdir -p $dossier_moodledata
		cecho "[OK]" green
	else
		cecho "[OK]" green
	fi

# Application des droits aux dossiers
	echo -n "- Changement des droits du dossier $dossier_moodledata : "
	if chmod 777 $dossier_moodledata ; then
		cecho "[OK]" green
	else
		cecho "[BAD]" red
	fi

# Changement des propriétaires des dossiers
	echo -n "- Changement des propriétaires des dossiers $dossier_moodle_racine : "
	if chown -R www-data: $dossier_moodle_racine/* ; then
		cecho "[OK]" green
	else
		cecho "[BAD]" red
	fi

# Installation de la source Moodle
	if [ -f ./moodle-*.tgz ] ; then
		echo
		cecho "Installation des sources depuis `ls moodle-*.tgz` :" yellow
		tar xfz ./moodle-*.tgz

		if mv moodle/* $dossier_moodle_systeme ; then
			cecho "[OK]" green
		else
			cecho "[BAD]" red
		fi
	else
		echo
		cecho "Récupération des sources github :" yellow
		if git clone https://github.com/moodle/moodle.git $dossier_moodle_systeme ; then
			cecho "[OK]" green
		else
			cecho "[BAD]" red
		fi
	fi

	echo
	cecho "Configuration de Apache et php5-fpm :" yellow

# Configuration du vHost Apache
	cp conf/moodle-http.conf /etc/apache2/sites-available/http-$urldusite.conf
	sed -i -e 's/email_demandeur/'"$email_demandeur"'/' /etc/apache2/sites-available/http-$urldusite.conf
	sed -i -e 's/urldusite/'"$urldusite"'/' /etc/apache2/sites-available/http-$urldusite.conf
	sed -i -e 's/dossier_moodle_racine/'"$compte_moodle"'/' /etc/apache2/sites-available/http-$urldusite.conf
	
# Autorisation du vHost et rechargement de la configuration apache
	if [ -f /etc/apache2/sites-enabled/*default* ]; then
		a2dissite *default* 2> /dev/null
		rm /etc/apache2/sites-available/*default*
	fi

	a2ensite http*-$urldusite.conf

# Sécurisation d'Apache
	sed -i -e 's/ServerTokens OS/ServerTokens Prod/' /etc/apache2/conf-available/security.conf
	sed -i -e 's/ServerSignature On/ServerSignature Off/' /etc/apache2/conf-available/security.conf

# Configuration de php5-fpm
	cp conf/php5-fpm.conf /etc/apache2/mods-available/php5-fpm.conf
	cp conf/php5-fpm.load /etc/apache2/mods-available/php5-fpm.load

	a2dismod php5 mpm_prefork > /dev/null
	a2enmod php5-fpm fastcgi actions mpm_worker > /dev/null
	service apache2 restart > /dev/null

# Création de la base de données et attribution des droits
	mysql -u root -p"$compte_db_root_mdp" -e "CREATE DATABASE $compte_moodle;"
	echo "GRANT ALL PRIVILEGES ON $compte_moodle.* TO $compte_moodle@'%' IDENTIFIED BY '$compte_db_moodle_mdp';" > ./compte_moodle.sql
	mysql -u root -p"$compte_db_root_mdp" < ./compte_moodle.sql

# Configuration de l'upload php5-fpm
	sed -i -e 's/upload_max_filesize = 2M/upload_max_filesize = 256M/' /etc/php5/fpm/php.ini
	sed -i -e 's/post_max_size = 8M/post_max_size = 256M/' /etc/php5/fpm/php.ini

# Configuration de OpCache
	sed -i -e 's/;opcache.enable=0/opcache.enable=1/' /etc/php5/fpm/php.ini
	sed -i -e 's/;opcache.memory_consumption=64/opcache.memory_consumption=250/' /etc/php5/fpm/php.ini
	sed -i -e 's/;;opcache.interned_strings_buffer=4/opcache.interned_strings_buffer=20/' /etc/php5/fpm/php.ini
	sed -i -e 's/;opcache.max_accelerated_files=2000/opcache.max_accelerated_files=5000/' /etc/php5/fpm/php.ini
	sed -i -e 's/;opcache.error_log=/opcache.error_log="/var/log/opcache.err.log"/' /etc/php5/fpm/php.ini

	service php5-fpm restart > /dev/null

# Installation automatique de Moodle
	php $dossier_moodle_systeme/admin/cli/install.php --allow-unstable --non-interactive --lang=fr --wwwroot=http://$urldusite --dataroot=$dossier_moodledata --dbname=$compte_moodle --dbuser=$compte_moodle --dbpass=$compte_db_moodle_mdp --fullname=$compte_moodle --shortname=$compte_moodle --adminuser=admin_symetrix --adminpass=symetrix --adminemail=$email_demandeur --agree-license

# Changement des propriétaires des dossiers
	echo -n "- Changement des propriétaires des dossiers $dossier_moodle_racine : "
	if chown -R www-data: $dossier_moodle_racine/* ; then
		cecho "[OK]" green
	else
		cecho "[BAD]" red
	fi

# Installation de opcachegui
	echo -n "- Installation du dossier opcache : "
	if cp -R apps/opcache /var/www/opcache ; then
		cecho "[OK]" green
	else
		cecho "[BAD]" red
	fi

# Changement des propriétaires des dossiers opcachegui
	echo -n "- Changement du propriétaire du dossier opcache : "
	if chown -R www-data: /var/www/opcache ; then
		cecho "[OK]" green
	else
		cecho "[BAD]" red
	fi

# Installation de phpmemcached
	echo -n "- Installation du dossier phpmemcached : "
	if cp -R apps/phpmemcached /var/www/phpmemcached ; then
		cecho "[OK]" green
	else
		cecho "[BAD]" red
	fi

# Changement des propriétaires des dossiers phpmemcached
	echo -n "- Changement du propriétaire du dossier phpmemcached : "
	if chown -R www-data: /var/www/phpmemcached ; then
		cecho "[OK]" green
	else
		cecho "[BAD]" red
	fi

# Configuration du cron
	echo "*/15 * * * * /usr/bin/php $dossier_moodle_systeme/admin/cli/cron.php > /dev/null" > /var/spool/cron/crontabs/www-data
	chown www-data:crontab /var/spool/cron/crontabs/www-data
	chmod 600 /var/spool/cron/crontabs/www-data

# Configuration de forcelogin
	mysql -u $compte_moodle -p$compte_db_moodle_mdp $compte_moodle -e "UPDATE mdl_config SET value='1' WHERE name='forcelogin'"

# Configuration de CLAMAV
	mysql -u $compte_moodle -p$compte_db_moodle_mdp $compte_moodle -e "UPDATE mdl_config SET value='1' WHERE name='runclamonupload'"
	mysql -u $compte_moodle -p$compte_db_moodle_mdp $compte_moodle -e "UPDATE mdl_config SET value='/usr/bin/clamscan' WHERE name='pathtoclam'"

# Configuration de DU
	mysql -u $compte_moodle -p$compte_db_moodle_mdp $compte_moodle -e "UPDATE mdl_config SET value='/usr/bin/du' WHERE name='pathtodu'"

# Configuration SMTP dans Moodle
	mysql -u $compte_moodle -p$compte_db_moodle_mdp $compte_moodle -e "UPDATE mdl_config SET value='smtp.gmail.com:587' WHERE name='smtphosts'" 
	mysql -u $compte_moodle -p$compte_db_moodle_mdp $compte_moodle -e "UPDATE mdl_config SET value='tls' WHERE name='smtpsecure'" 
	mysql -u $compte_moodle -p$compte_db_moodle_mdp $compte_moodle -e "UPDATE mdl_config SET value='no-reply@symetrix.fr' WHERE name='smtpuser'"
	mysql -u $compte_moodle -p$compte_db_moodle_mdp $compte_moodle -e "UPDATE mdl_config SET value='N0ReplySym' WHERE name='smtppass'"
	mysql -u $compte_moodle -p$compte_db_moodle_mdp $compte_moodle -e "UPDATE mdl_config SET value='10' WHERE name='smtpmaxbulk'"

# Envoie des informations par email
	body="- Email du demandeur : $email_demandeur
	- URL du vHost : $urldusite
	- Protocole utilisé : $protocole
	- Compte système Moodle : $compte_moodle
	- Mot de passe du compte système Moodle : $compte_moodle_mdp
	- Dossier d'installation racine : $dossier_moodle_racine
	- Dossier système Moodle : $dossier_moodle_systeme
	- Dossier data Moodle : $dossier_moodledata
	- Compte root base de données : root
	- Mot de passe du compte root base de données : $compte_db_root_mdp
	- Nom de la base de données : $compte_moodle
	- Utilisateur de la base de donnée : $compte_moodle
	- Mot de passe de l'utilisateur base de donnée : $compte_db_moodle_mdp"

	echo $body | mail -s "$urldusite est prêt !" $email_demandeur

# Installation de Ohmyzsh
	echo -n "- Installation de Ohmyzsh : "
	if sh -c "$(wget https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh -O -); exit" > /dev/null ; then
		cecho "[OK]" green
		sed -i -e "s/robbyrussell/ys/" $HOME/.zshrc
	else
		cecho "[BAD]" red
	fi