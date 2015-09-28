<?php

define('CLI_SCRIPT', true);

require_once '$dossier_moodle_systeme/moodle/config.php';

//Regles mots de passe
set_config('passwordpolicy', 0);

//Completion
set_config('enablecompletion', 1);
set_config('enableavailability', 1);

//mode debug
set_config('debug', 32767);
set_config('debugdisplay', 1);

//mode concepteur
set_config('themedesignermode', 1);
set_config('cachejs', 0);
set_config('langstringcache', 0);

//format de cours
set_config('disabled', 1, 'format_social');

//blocs
$DB->execute('UPDATE {block} SET visible = 0 WHERE name = "navigation"');
$DB->execute('UPDATE {block} SET visible = 0 WHERE name = "recent_activity"');
$DB->execute('UPDATE {block} SET visible = 0 WHERE name = "course_summary"');
$DB->execute('UPDATE {block} SET visible = 0 WHERE name = "search_forums"');
$DB->execute('UPDATE {block} SET visible = 0 WHERE name = "news_items"');
$DB->execute('UPDATE {block} SET visible = 0 WHERE name = "feedback"');
$DB->execute('UPDATE {block} SET visible = 0 WHERE name = "course_overview"');
$DB->execute('UPDATE {block} SET visible = 0 WHERE name = "community"');
$DB->execute('UPDATE {block} SET visible = 0 WHERE name = "admin_bookmarks"');
$DB->execute('UPDATE {block} SET visible = 0 WHERE name = "calendar_upcoming"');

//modules
$DB->execute('UPDATE {modules} SET visible = 0 WHERE name = "imscp"');
$DB->execute('UPDATE {modules} SET visible = 0 WHERE name = "book"');
$DB->execute('UPDATE {modules} SET visible = 0 WHERE name = "lti"');
$DB->execute('UPDATE {modules} SET visible = 0 WHERE name = "survey"');
$DB->execute('UPDATE {modules} SET visible = 0 WHERE name = "workshop"');
$DB->execute('UPDATE {modules} SET visible = 0 WHERE name = "feedback"');
$DB->execute('UPDATE {modules} SET visible = 0 WHERE name = "data"');

//scorm
set_config('displayactivityname', 0, 'scorm');
set_config('skipview', 2, 'scorm');
set_config('hidetoc', 3, 'scorm');
set_config('nav', 0, 'scorm');

//page accueil
set_config('frontpage', '');
set_config('frontpageloggedin', '');

//options inutiles
set_config('usecomments', 0);
set_config('usetags', 0);
set_config('enableblogs', 0);
set_config('enablebadges', 0);
?>
