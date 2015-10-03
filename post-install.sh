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

# Chemin sources dans le dossier d'installation
path_src_conf_apache='./conf/apache'
path_src_conf_moodle='./conf/moodle'
path_src_conf_php='./conf/php'
path_src_conf_ssmtp='./conf/ssmtp'
path_src_conf_system='./conf/system'

# Chemin distant sur le serveur
path_dst_conf_apache='/etc/apache2/sites-available'

# APT source files
file_src_apt_source="$path_src_conf_system/sources.list" 
file_dst_apt_source='/etc/apt/sources.list'

# VIM config files
file_src_vim_conf="$path_src_conf_system/.vimrc"
file_dst_vim_conf="$HOME/.vimrc"

# SSMTP Config files
file_src_ssmtp_conf="$path_src_conf_ssmtp/ssmtp.conf"
file_dst_ssmtp_conf='/etc/ssmtp/ssmtp.conf'
file_src_ssmtp_revaliases="$path_src_conf_ssmtp/revaliases"
file_dst_ssmtp_revaliases='/etc/ssmtp/revaliases'

# Apticron config
file_dst_apticron_conf='/etc/apticron/apticron.conf'
file_dst_unattended_upggrades='/etc/apt/apt.conf.d/50unattended-upgrades'

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

# -------------------- Adresse email du demandeur --------------------
	echo -n "Entrer votre adresse e-mail (les informations de connexions vous seront envoyées) : "
	read email_demandeur

# -------------------- URL du Moodle à installer --------------------
	echo -n "Entrer l'URL du Moodle : "
	read urldusite

# -------------------- Choix du protocole HTTP --------------------
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

# -------------------- Définition du compte --------------------
	account_system_moodle_name=`echo $urldusite | cut -f1 -d.`
	account_system_moodle_password=`pwgen -1`
	account_db_moodle_password=`pwgen -1`
	account_db_root_password=`pwgen -1`

# -------------------- Définition du dossier racine moodle --------------------
	folder_moodle_root="/var/www/$account_system_moodle_name"
	folder_moodle_system="$folder_moodle_root/moodle"
    folder_moodle_data="$folder_moodle_root/moodledata"

# -------------------- Affichage des variables à l'écran pour contrôle --------------------
	echo "Ceci va définir les variables de scripts suivants :"
	echo "- Email du demandeur : $email_demandeur"
	echo "- URL du vHost : $urldusite"
	echo "- Protocole utilisé : $protocole"
	echo "- Compte système Moodle : $account_system_moodle_name"
	echo "- Mot de passe du compte système Moodle : $account_system_moodle_password"
	echo "- Dossier d'installation racine : $folder_moodle_root"
	echo "- Dossier système Moodle : $folder_moodle_system"
	echo "- Dossier data Moodle : $folder_moodle_data"
	echo "- Compte root base de données : root"
	echo "- Mot de passe du compte root base de données : $account_db_root_password"
	echo "- Nom de la base de données : $account_system_moodle_name"
	echo "- Utilisateur de la base de donnée : $account_system_moodle_name"
	echo "- Mot de passe de l'utilisateur base de donnée : $account_db_moodle_password"
	echo

# -------------------- Confirmation des variables par l'utilisateur --------------------
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

# -------------------- Modification du fichier des sources --------------------
	echo -n "- Modification du fichier sources.list : "
	if cat $file_src_apt_source > $file_dst_apt_source ; then
		cecho "[OK]" green
	else
		cecho "[BAD]" red
	fi

# -------------------- Mise à jour du système --------------------
	echo -n "- Mise à jour du Système : "
	if apt-get update > /dev/null && apt-get upgrade -y > /dev/null && apt-get check > /dev/null && apt-get autoclean > /dev/null && apt-get autoremove > /dev/null ; then
		cecho "[OK]" green
	else
		cecho "[BAD]" red
	fi

# -------------------- Configuration de MySQL avant installation --------------------
	debconf-set-selections <<< "mysql-server mysql-server/root_password password $account_db_root_password"
	debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $account_db_root_password"

# -------------------- Installation des paquets de base --------------------
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

# -------------------- Configuration de VIM --------------------
	echo -n "- Configuration de VIM : "
	if cat $file_src_vim_conf > $file_dst_vim_conf ; then
		cecho "[OK]" green
	else
		cecho "[BAD]" red
	fi

# -------------------- Configuration de SSMTP --------------------
	echo -n "- Configuration de SSMTP : "
	if cat $file_src_ssmtp_conf > $file_dst_ssmtp_conf ; then
		cecho "[OK]" green
	else
		cecho "[BAD]" red
	fi

	sed -i -e 's/nom_hote/`hostname`/' $file_dst_ssmtp_conf

	echo -n "- Configuration de revaliases : "
	if cat $file_src_ssmtp_revaliases > $file_dst_ssmtp_revaliases ; then
		cecho "[OK]" green
	else
		cecho "[BAD]" red
	fi

	echo
	cecho "Compte et arborescence Moodle :" yellow

# -------------------- Configuration de apticron --------------------
	sed -i -e 's/EMAIL="root"/EMAIL="'"$email_demandeur"'"/' $file_dst_apticron_conf
	sed -i -e 's/# SYSTEM="foobar.example.com"/SYSTEM="'"$urldusite - `hostname`"'"/' $file_dst_apticron_conf

# -------------------- Configuration de unattended-upgrade --------------------
	sed -i -e 's/Unattended-Upgrade::Mail "root";/Unattended-Upgrade::Mail "'"$email_demandeur"'";/' $file_dst_unattended_upggrades

# -------------------- Création de l'utilisateur Moodle --------------------
	echo -n "- Création du compte $account_system_moodle_name : "
	if useradd $account_system_moodle_name ; then
		cecho "[OK]" green
		echo "$account_system_moodle_name:$account_system_moodle_password" | chpasswd
	else
		cecho "[BAD]" red
	fi

# -------------------- Création de l'arborescence --------------------
	echo -n "- Création du dossier $folder_moodle_system : "
	if mkdir -p $folder_moodle_system ; then	
		cecho "[OK]" green
	else
		cecho "[OK]" green
	fi
	
	echo -n "- Création du dossier $folder_moodle_data : "
	if mkdir -p $folder_moodle_data ; then
		cecho "[OK]" green
	else
		cecho "[OK]" green
	fi

	echo -n "- Changement des droits du dossier $folder_moodle_data : "
	if chmod 777 $folder_moodle_data ; then
		cecho "[OK]" green
	else
		cecho "[BAD]" red
	fi

	echo -n "- Changement des propriétaires des dossiers $folder_moodle_root : "
	if chown -R www-data: $folder_moodle_root/* ; then
		cecho "[OK]" green
	else
		cecho "[BAD]" red
	fi

# -------------------- Installation des sources Moodle --------------------
	if [ -f ./moodle-*.tgz ] ; then
		echo
		cecho "Installation des sources depuis `ls moodle-*.tgz` :" yellow
		tar xfz ./moodle-*.tgz

		if mv moodle/* $folder_moodle_system ; then
			cecho "[OK]" green
		else
			cecho "[BAD]" red
		fi
	else
		echo
		cecho "Récupération des sources github :" yellow
		if git clone https://github.com/moodle/moodle.git $folder_moodle_system ; then
			cecho "[OK]" green
		else
			cecho "[BAD]" red
		fi
	fi

	echo
	cecho "Configuration de Apache et php5-fpm :" yellow

# Configuration du vHost Apache
	cp $path_conf_apache/moodle-http.conf /etc/apache2/sites-available/http-$urldusite.conf
	sed -i -e 's/email_demandeur/'"$email_demandeur"'/' /etc/apache2/sites-available/http-$urldusite.conf
	sed -i -e 's/urldusite/'"$urldusite"'/' /etc/apache2/sites-available/http-$urldusite.conf
	sed -i -e 's/folder_moodle_root/'"$account_system_moodle_name"'/' /etc/apache2/sites-available/http-$urldusite.conf
	
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
	mysql -u root -p"$account_db_root_password" -e "CREATE DATABASE $account_system_moodle_name;"
	echo "GRANT ALL PRIVILEGES ON $account_system_moodle_name.* TO $account_system_moodle_name@'%' IDENTIFIED BY '$account_db_moodle_password';" > ./account_system_moodle_name.sql
	mysql -u root -p"$account_db_root_password" < ./account_system_moodle_name.sql

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
	php $folder_moodle_system/admin/cli/install.php --allow-unstable --non-interactive --lang=fr --wwwroot=http://$urldusite --dataroot=$folder_moodle_data --dbname=$account_system_moodle_name --dbuser=$account_system_moodle_name --dbpass=$account_db_moodle_password --fullname=$account_system_moodle_name --shortname=$account_system_moodle_name --adminuser=admin_symetrix --adminpass=symetrix --adminemail=$email_demandeur --agree-license

# Changement des propriétaires des dossiers
	echo -n "- Changement des propriétaires des dossiers $folder_moodle_root : "
	if chown -R www-data: $folder_moodle_root/* ; then
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
	echo "*/15 * * * * /usr/bin/php $folder_moodle_system/admin/cli/cron.php > /dev/null" > /var/spool/cron/crontabs/www-data
	chown www-data:crontab /var/spool/cron/crontabs/www-data
	chmod 600 /var/spool/cron/crontabs/www-data

# Configuration de forcelogin
	mysql -u $account_system_moodle_name -p$account_db_moodle_password $account_system_moodle_name -e "UPDATE mdl_config SET value='1' WHERE name='forcelogin'"

# Configuration de CLAMAV
	mysql -u $account_system_moodle_name -p$account_db_moodle_password $account_system_moodle_name -e "UPDATE mdl_config SET value='1' WHERE name='runclamonupload'"
	mysql -u $account_system_moodle_name -p$account_db_moodle_password $account_system_moodle_name -e "UPDATE mdl_config SET value='/usr/bin/clamscan' WHERE name='pathtoclam'"

# Configuration de DU
	mysql -u $account_system_moodle_name -p$account_db_moodle_password $account_system_moodle_name -e "UPDATE mdl_config SET value='/usr/bin/du' WHERE name='pathtodu'"

# Configuration SMTP dans Moodle
	mysql -u $account_system_moodle_name -p$account_db_moodle_password $account_system_moodle_name -e "UPDATE mdl_config SET value='smtp.gmail.com:587' WHERE name='smtphosts'" 
	mysql -u $account_system_moodle_name -p$account_db_moodle_password $account_system_moodle_name -e "UPDATE mdl_config SET value='tls' WHERE name='smtpsecure'" 
	mysql -u $account_system_moodle_name -p$account_db_moodle_password $account_system_moodle_name -e "UPDATE mdl_config SET value='no-reply@symetrix.fr' WHERE name='smtpuser'"
	mysql -u $account_system_moodle_name -p$account_db_moodle_password $account_system_moodle_name -e "UPDATE mdl_config SET value='N0ReplySym' WHERE name='smtppass'"
	mysql -u $account_system_moodle_name -p$account_db_moodle_password $account_system_moodle_name -e "UPDATE mdl_config SET value='10' WHERE name='smtpmaxbulk'"

# Envoie des informations par email
	body="- Email du demandeur : $email_demandeur
	- URL du vHost : $urldusite
	- Protocole utilisé : $protocole
	- Compte système Moodle : $account_system_moodle_name
	- Mot de passe du compte système Moodle : $account_system_moodle_password
	- Dossier d'installation racine : $folder_moodle_root
	- Dossier système Moodle : $folder_moodle_system
	- Dossier data Moodle : $folder_moodle_data
	- Compte root base de données : root
	- Mot de passe du compte root base de données : $account_db_root_password
	- Nom de la base de données : $account_system_moodle_name
	- Utilisateur de la base de donnée : $account_system_moodle_name
	- Mot de passe de l'utilisateur base de donnée : $account_db_moodle_password"

	echo $body | mail -s "$urldusite est prêt !" $email_demandeur

# Installation de Ohmyzsh
	echo -n "- Installation de Ohmyzsh : "
	if sh -c "$(wget https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh -O -); exit" > /dev/null ; then
		cecho "[OK]" green
		sed -i -e "s/robbyrussell/ys/" $HOME/.zshrc
	else
		cecho "[BAD]" red
	fi