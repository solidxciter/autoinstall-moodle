# --------------------------------------------------------------
#!/bin/bash
# Script d'installation automatique serveur LAMP + Moodle
#
#	Ecrit par Kenny CALVAT. Symetrix.
#	Version 1.0
#	Date : 10/06/2015
#
# --------------------------------------------------------------

# --------------------------------------------------------------
# Les variables
# --------------------------------------------------------------

# Compte email
smtp_server='smtp.gmail.com'
stmp_user='kenny.calvat@gmail.com'
smtp_password=''
smtp_port='587'

# Les chemins
fichierSources='/etc/apt/sources.list'
fichierLog='log/postinstall.log'

# Gestion des paquets
paquets_ssh="openssh-client openssh-server "
paquets_editeur="nano vim git zsh "
paquets_stats="htop nmon logwatch "
paquets_apache="apache2-mpm-worker libapache2-mod-php5 libapache2-mod-fastcgi "
paquets_mysql="mysql-server mysql-client "
paquets_php="php5 php5-mysqlnd php5-curl php5-xmlrpc php5-gd php5-intl php5-fpm "
paquets_email="ssmtp "
paquets_securite="pwgen fail2ban rkhunter apticron unattended-upgrades "
liste_paquets="$paquets_ssh $paquets_editeur $paquets_stats $paquets_administration $paquets_apache $paquets_php $paquets_email $paquets_securite"

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
# Les fonctions de configuration
# --------------------------------------------------------------

function mettre-a-jour() { # Fonction qui met à jour les applications et nettoie la base de paquets
	echo
	cecho "Mise à jour du système" yellow
    cecho "---------------------------------------------------------" yellow
	echo

	apt-get update  && apt-get upgrade -y && apt-get check && apt-get autoclean && apt-get autoremove
}

function modifier-sources() { # Fonction qui modifie le fichier des sources
# Sauvegarde le fichier courant des sources. Le numéro final le plus grand et le fichier le plus récent.
	if ! [ -f /etc/apt/sources.list.old.1 ] ; then
		cp $fichierSources /etc/apt/sources.list.old.1
	else
# Récupère le dernier numéro de version et l'incrémente de 1
		numero=`ls /etc/apt/sources* | sort -r | head -1 | cut -d. -f4`
		numero=$(($numero + 1))

		cp $fichierSources /etc/apt/sources.list.old.$numero
	fi

	echo "deb http://ftp.fr.debian.org/debian/ jessie main contrib non-free" > $fichierSources
	echo "deb-src http://ftp.fr.debian.org/debian/ jessie main contrib non-free" >> $fichierSources
	echo "deb http://security.debian.org/ jessie/updates main contrib non-free" >> $fichierSources
	echo "deb-src http://security.debian.org/ jessie/updates main contrib non-free" >> $fichierSources
	echo "deb http://ftp.fr.debian.org/debian/ jessie-updates main" >> $fichierSources
	echo "deb-src http://ftp.fr.debian.org/debian/ jessie-updates main" >> $fichierSources
}

# --------------------------------------------------------------
# Les fonctions d'installation
# --------------------------------------------------------------
function installer-moodle() { # Fonction qui installe la dernière version de Moodle

# Affichage de la bannière
	echo
	cecho "Installation de Moodle" yellow
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
	if chown -R $compte_moodle:www-data $dossier_moodle_racine/* ; then
		cecho "[OK]" green
	else
		cecho "[BAD]" red
	fi
	
# Récupération de la source Moodle	
	git clone https://github.com/moodle/moodle.git $dossier_moodle_systeme

# Configuration du vHost Apache
	cp conf/moodle-http.conf /etc/apache2/sites-available/http-$urldusite.conf
	sed -i -e 's/urldusite/'"$urldusite"'/' /etc/apache2/sites-available/http-$urldusite.conf
	sed -i -e 's/dossier_moodle_racine/'"$compte_moodle"'/' /etc/apache2/sites-available/http-$urldusite.conf
	
# Autorisation du vHost et rechargement de la configuration apache
	if [ -f /etc/apache2/sites-enabled/*default* ]; then
		a2dissite *default* 2> /dev/null
		rm /etc/apache2/sites-available/*default*
	fi

	a2ensite http-$urldusite.conf
	service apache2 restart

# Création de la base de données et attribution des droits
	mysql -u root -p"$compte_db_root_mdp" -e "CREATE DATABASE $compte_moodle; GRANT ALL PRIVILEGES ON $compte_moodle.* TO $compte_moodle@'%' IDENTIFIED BY 'compte_db_moodle_mdp';"
}

# --------------------------------------------------------------
# Installation du shell ZSH
# --------------------------------------------------------------

function installer-ohmyzsh() {
# Récupération de la source
	sh -c "$(wget https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh -O -)"

# Modification du thème
	sed -i -e "s/robbyrussell/ys/g" $HOME/.zshrc

# Modification du shell pour l'utilisateur courant
	usermod -s /usr/bin/zsh $USER
}

# --------------------------------------------------------------
# Installation d'Apache
# --------------------------------------------------------------

function installer-apache() { # Fonction qui installe Apache2 en mode mpm_worker
	echo
	cecho "Installation de Apache2" yellow
    cecho "---------------------------------------------------------" yellow
	echo
	apt-get install -y $paquets_apache
	activer-worker
}

function installer-fastcgi() { # Fonction qui installe le mod_fastcgi dans Apache2
	modifier-sources
	mettre-a-jour

	apt-get install -y libapache2-mod-fastcgi

# Installation des fichiers de configuration
	cat conf/php5-fpm.conf > /etc/apache2/mods-available/php5-fpm.conf
	cat conf/php5-fpm.load > /etc/apache2/mods-available/php5-fpm.load

# Activation du module dans Apache
	a2dismod php5
	a2enmod php5-fpm fastcgi actions
}

function installer-php5 () { # Fonction qui installe l'ensemble des mods php utiles à Moodle
# Installation des paquets nécessaire à Moodle
	apt-get install -y libapache2-mod-php5 php5-fpm php5-mysqlnd php5-curl php5-xmlrpc php5-gd php5-intl

# Installation de module fastcgi pour Apache
	installer-fastcgi

# Réactive le mpm-worker (peut rebasculer en prefork)
	activer-worker
}

# --------------------------------------------------------------
# Installation de MySQL
# --------------------------------------------------------------

function installer-mysql () { # Fonction qui installe le serveur et le client MySQL
	debconf-set-selections <<< 'mysql-server mysql-server/root_password password $compte_db_root_mdp'
	debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password $compte_db_root_mdp'
	apt-get -y install $paquets_mysql
}

# --------------------------------------------------------------
# Installation de SSMTP
# --------------------------------------------------------------

function installer-sendmail() { # Fonction qui installe un client mail
	apt-get install -y $paquets_email
}

function installer-lamp() {
	echo "Installation des paquets :"

	for paquet in $liste_paquets ; do
		echo -n "- $paquet : "
		if apt-get install -y $paquet > /dev/null ; then
			cecho "[OK]" green
		else
			cecho "[BAD]" red
		fi
	done
}

function activer-worker() { # Fonction qui active le mod mpm_worker dans Apache2
	a2dismod mpm_prefork
	a2enmod mpm_worker
	service apache2 restart
}

# --------------------------------------------------------------
# Les fonction de déinstallation
# --------------------------------------------------------------

function desinstaller-apache() { # Fonction qui désinstalle Apache2
	echo
    cecho "Dénstallation de Apache" yellow
    cecho "---------------------------------------------------------" yellow
	apt-get autoremove --purge --yes $paquets_apache
}

function desinstaller-mysql() { # Fonction qui désinstalle MySQL
	echo
    cecho "Dénstallation de MySQL" yellow
    cecho "---------------------------------------------------------" yellow
    apt-get autoremove --purge --yes $paquets_mysql
}

function desinstaller-php5() { # Fonction qui désinstalle php5
	echo
    cecho "Dénstallation de PHP" yellow
    cecho "---------------------------------------------------------" yellow
    apt-get autoremove --purge--yes $paquets_php
}

function desinstaller-sendmail() { # Fonction qui désinstalle sendmail
	echo
    cecho "Dénstallation de SSMTP" yellow
    cecho "---------------------------------------------------------" yellow
    apt-get autoremove --purge --yes $paquets_email
}

function desinstaller-lamp() { # Fonction qui désinstalle LAMP

    echo
    cecho "Dénstallation du serveur LAMP" yellow
    cecho "---------------------------------------------------------" yellow

    apt-get autoremove --purge --yes $liste_paquets
}

# --------------------------------------------------------------
# L'exécution du script
# --------------------------------------------------------------

case "$1" in
	-iz)
		installer-ohmyzsh
	;;
	-test)
		modifier-sources
	;;
	-maj)
		mettre-a-jour
	;;
	-ia)
		installer-apache
	;;
	-ic)
		# Affichage de la bannière
		echo
		cecho "Installation de fastcgi" yellow
	    cecho "---------------------------------------------------------" yellow
		echo

		installer-fastcgi
	;;
	-im)
		# Affichage de la bannière
		echo
		cecho "Installation de MySQL" yellow
	    cecho "---------------------------------------------------------" yellow
		echo

		installer-mysql
	;;
	-ip)
		# Affichage de la bannière
		echo
		cecho "Installation de php5" yellow
	    cecho "---------------------------------------------------------" yellow
		echo

		installer-php5
	;;
	-is)
		# Affichage de la bannière
		echo
		cecho "Installation de SendMail" yellow
	    cecho "---------------------------------------------------------" yellow
		echo

		installer-sendmail
	;;
	-il)
		# Affichage de la bannière
		echo
		cecho "---------------------------------------------------------" yellow
		cecho "Installation d'un serveur LAMP Moodle" yellow
	    cecho "---------------------------------------------------------" yellow
		echo

		modifier-sources
		#mettre-a-jour
		installer-lamp
		installer-moodle
	;;
	-da)
		desinstaller-apache
	;;
	-dc)
		desinstaller-fastcgi
	;;
	-dm)
		desinstaller-mysql
	;;
	-dp)
		desinstaller-php5
	;;
	-ds)
		desinstaller-sendmail
	;;
	-dl)
		desinstaller-lamp
	;;
esac