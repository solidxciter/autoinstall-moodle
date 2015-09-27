# --------------------------------------------------------------
# Fichier de fonction
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


# Installation de MySQL
# --------------------------------------------------------------

function installer-mysql () { # Fonction qui installe le serveur et le client MySQL
	debconf-set-selections <<< 'mysql-server mysql-server/root_password password $compte_db_root_mdp'
	debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password $compte_db_root_mdp'
	apt-get -y install $paquets_mysql
}


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