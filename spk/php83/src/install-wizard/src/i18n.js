// Internationalization for PHP 8.3 wizard
// Auto-generated from extensions.json - DO NOT EDIT MANUALLY

const translations = {
  en: {
    title: 'PHP 8.3 Extension Configuration',
    intro: 'PHP 8.3.28 has been compiled with 39 extensions (CLI and OPcache are built-in). Select which extensions to enable. You can modify these settings later in Package Center.',
    selectAll: 'Select All',
    deselectAll: 'Deselect All',
    native: 'native',

    categories: {
      core: 'Core Extensions',
      math: 'Mathematics',
      xml: 'XML & Text Processing',
      databases: 'Database Extensions',
      network: 'Network & Protocols',
      compression: 'Compression & Archives',
      images: 'Image Processing',
      io: 'File I/O & Sessions',
      system: 'System & Process',
      i18n: 'Internationalization',
    },

    extensions: {
      // Core Extensions
      opcache: 'OPcache - Bytecode cache for improved performance',
      tokenizer: 'Tokenizer - PHP tokenizer for parsing PHP code',
      filter: 'Filter - Input validation and filtering',
      ctype: 'Ctype - Character type checking functions',

      // Mathematics
      bcmath: 'BCMath - Arbitrary precision mathematics',

      // XML & Text Processing
      xml: 'XML - XML parser support',
      dom: 'DOM - Document Object Model',
      simplexml: 'SimpleXML - Simple XML parsing',
      xmlreader: 'XMLReader - XML Pull Parser',
      xmlwriter: 'XMLWriter - XML document generation',
      soap: 'SOAP - SOAP web services',

      // Database Extensions
      pdo: 'PDO - PHP Data Objects (required for PDO drivers)',
      mysqli: 'MySQLi - MySQL improved extension',
      mysqlnd: 'MySQL Native Driver - MySQL native driver (required for mysqli)',
      pdo_mysql: 'PDO MySQL - PDO driver for MySQL',
      sqlite3: 'SQLite3 - SQLite 3 database support',
      pdo_sqlite: 'PDO SQLite - PDO driver for SQLite',
      dba: 'DBA - Database abstraction layer',

      // Network & Protocols
      curl: 'cURL - Client URL library',
      openssl: 'OpenSSL - OpenSSL cryptographic functions',
      ftp: 'FTP - FTP client functions',
      sockets: 'Sockets - Low-level socket communication',

      // Compression & Archives
      zlib: 'Zlib - Zlib compression',
      bz2: 'Bzip2 - Bzip2 compression',
      phar: 'Phar - PHP Archive support',

      // Image Processing
      gd: 'GD - Image processing (PNG, JPEG, WebP, FreeType)',
      exif: 'EXIF - Read EXIF headers from images',

      // File I/O & Sessions
      fileinfo: 'Fileinfo - File information and MIME type detection',
      session: 'Session - Session management',

      // System & Process
      posix: 'POSIX - POSIX functions',
      pcntl: 'PCNTL - Process control support',
      shmop: 'Shmop - Shared memory operations',
      sysvmsg: 'System V Messages - System V message queue support',
      sysvsem: 'System V Semaphores - System V semaphore support',
      sysvshm: 'System V Shared Memory - System V shared memory support',

      // Internationalization
      gettext: 'Gettext - GNU gettext internationalization',
      iconv: 'Iconv - Character encoding conversion',
      intl: 'Intl - Internationalization extension (ICU)',
      calendar: 'Calendar - Calendar conversion functions',

    }
  },

  fre: {
    title: "Configuration des Extensions PHP 8.3",
    intro: "PHP 8.3.28 a été compilé avec 39 extensions (CLI et OPcache sont natifs). Sélectionnez les extensions à activer. Vous pourrez modifier ces paramètres ultérieurement dans le Centre de paquets.",
    selectAll: "Tout sélectionner",
    deselectAll: "Tout désélectionner",
    native: "natif",

    categories: {
      core: "Extensions de base",
      math: "Mathématiques",
      xml: "Traitement XML",
      databases: "Extensions de base de données",
      network: "Réseau et protocoles",
      compression: "Compression et archives",
      images: "Traitement d'images",
      io: "Fichiers et sessions",
      system: "Système et processus",
      i18n: "Internationalisation",
    },

    extensions: {
      // Extensions de base
      opcache: "OPcache - Cache de bytecode pour améliorer les performances",
      tokenizer: "Tokenizer - Analyseur de code PHP",
      filter: "Filter - Validation et filtrage des entrées",
      ctype: "Ctype - Vérification des types de caractères",

      // Mathématiques
      bcmath: "BCMath - Mathématiques en précision arbitraire",

      // Traitement XML
      xml: "XML Parser - Analyse XML de base",
      dom: "DOM - Modèle objet de document XML",
      simplexml: "SimpleXML - Interface XML simplifiée",
      xmlreader: "XMLReader - Analyseur XML Pull",
      xmlwriter: "XMLWriter - Génération de documents XML",
      soap: "SOAP - Services web SOAP",

      // Extensions de base de données
      pdo: "PDO - Couche d'abstraction de base de données",
      mysqli: "MySQLi - Interface MySQL améliorée",
      mysqlnd: "MySQL Native Driver - Pilote MySQL natif",
      pdo_mysql: "PDO MySQL - Pilote MySQL/MariaDB",
      sqlite3: "SQLite3 - Support de base de données SQLite 3",
      pdo_sqlite: "PDO SQLite - Pilote SQLite",
      dba: "DBA - Couche d'abstraction de base de données",

      // Réseau et protocoles
      curl: "cURL - Bibliothèque client HTTP",
      openssl: "OpenSSL - Cryptographie SSL/TLS",
      ftp: "FTP - Client File Transfer Protocol",
      sockets: "Sockets - Communication réseau bas niveau",

      // Compression et archives
      zlib: "Zlib - Compression gzip",
      bz2: "BZip2 - Compression bzip2",
      phar: "Phar - Support des archives PHP",

      // Traitement d'images
      gd: "GD - Manipulation d'images (PNG, JPEG, WebP, FreeType)",
      exif: "EXIF - Lecture des métadonnées d'images",

      // Fichiers et sessions
      fileinfo: "Fileinfo - Détection du type de fichier",
      session: "Session - Gestion des sessions",

      // Système et processus
      posix: "POSIX - Fonctions système Unix",
      pcntl: "PCNTL - Contrôle de processus (fork, signaux)",
      shmop: "Shmop - Opérations de mémoire partagée",
      sysvmsg: "System V Messages - Files de messages System V",
      sysvsem: "System V Semaphores - Sémaphores System V",
      sysvshm: "System V Shared Memory - Mémoire partagée System V",

      // Internationalisation
      gettext: "Gettext - Texte multilingue",
      iconv: "Iconv - Conversion d'encodage de caractères",
      intl: "Intl - Internationalisation (ICU)",
      calendar: "Calendar - Fonctions de conversion de calendrier",

    }
  }
};

// Detect system language from DSM
export function getSystemLanguage() {
  // Try to get language from DSM global variable
  if (typeof _S === 'function') {
    const lang = _S('lang');
    if (lang && translations[lang]) {
      return lang;
    }
  }

  // Fallback to browser language
  const browserLang = navigator.language || navigator.userLanguage;
  if (browserLang.startsWith('fr')) return 'fre';

  return 'en'; // Default to English
}

// Get translation function
export function useI18n() {
  const lang = getSystemLanguage();
  const t = translations[lang] || translations.en;

  return {
    t,
    lang
  };
}
