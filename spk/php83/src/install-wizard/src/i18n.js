// Internationalization for PHP 8.3 wizard

const translations = {
  en: {
    title: 'PHP 8.3 Extension Configuration',
    intro: 'PHP 8.3.8 has been compiled with 36 extensions. Select which extensions to enable. You can modify these settings later in Package Center.',
    selectAll: 'Select All',
    deselectAll: 'Deselect All',
    native: 'native',

    categories: {
      core: 'Core Extensions',
      coreDesc: 'Essential PHP core functionality (recommended)',
      database: 'Database Extensions',
      databaseDesc: 'MySQL/MariaDB and SQLite support',
      network: 'Web & Network',
      networkDesc: 'cURL, OpenSSL, and networking',
      images: 'Image Processing',
      imagesDesc: 'GD library with PNG/JPEG/WebP',
      xml: 'XML Processing',
      compression: 'Compression & Archives',
      i18n: 'Internationalization',
      advanced: 'Advanced Extensions',
      advancedDesc: 'Math, System, and other'
    },

    extensions: {
      // Core
      opcache: 'OPcache - Bytecode cache for improved performance',
      tokenizer: 'Tokenizer - PHP tokenizer',
      filter: 'Filter - Input validation and filtering',
      ctype: 'Ctype - Character type checking',
      cli: 'CLI - Command Line Interface',
      session: 'Session - Session handling',
      phar: 'Phar - PHP Archive',

      // Database
      pdo: 'PDO - Database abstraction layer',
      pdo_mysql: 'PDO MySQL - MySQL/MariaDB driver',
      mysqli: 'MySQLi - Improved MySQL interface',
      pdo_sqlite: 'PDO SQLite - SQLite driver',

      // Network
      curl: 'cURL - HTTP client library',
      openssl: 'OpenSSL - SSL/TLS cryptography',
      ftp: 'FTP - File Transfer Protocol client',
      sockets: 'Sockets - Low-level networking',

      // Images
      gd: 'GD - Image manipulation (PNG, JPEG, WebP, FreeType)',
      exif: 'EXIF - Read image metadata',

      // XML
      dom: 'DOM - XML Document Object Model',
      xml: 'XML Parser - Basic XML parsing',
      simplexml: 'SimpleXML - Simple XML interface',

      // Compression
      zip: 'Zip - ZIP archive support',
      zlib: 'Zlib - gzip compression',
      bz2: 'BZip2 - bzip2 compression',

      // I18n
      mbstring: 'Mbstring - Multibyte string functions',
      intl: 'Intl - Internationalization (ICU)',
      gettext: 'Gettext - Multilingual text',
      iconv: 'Iconv - Character encoding conversion',

      // Advanced
      bcmath: 'BCMath - Arbitrary precision mathematics',
      gmp: 'GMP - GNU Multiple Precision',
      sodium: 'Sodium - Modern cryptography',
      fileinfo: 'Fileinfo - File type detection',
      posix: 'POSIX - Unix system functions',
      pcntl: 'PCNTL - Process control (fork, signals)'
    }
  },

  fre: {
    title: 'Configuration des Extensions PHP 8.3',
    intro: 'PHP 8.3.8 a été compilé avec 36 extensions. Sélectionnez les extensions à activer. Vous pourrez modifier ces paramètres ultérieurement dans le Centre de paquets.',
    selectAll: 'Tout sélectionner',
    deselectAll: 'Tout désélectionner',
    native: 'natif',

    categories: {
      core: 'Extensions de base',
      coreDesc: 'Fonctionnalités essentielles de PHP (recommandé)',
      database: 'Extensions de base de données',
      databaseDesc: 'Support MySQL/MariaDB et SQLite',
      network: 'Web et réseau',
      networkDesc: 'cURL, OpenSSL et fonctions réseau',
      images: 'Traitement d\'images',
      imagesDesc: 'Bibliothèque GD avec PNG/JPEG/WebP',
      xml: 'Traitement XML',
      compression: 'Compression et archives',
      i18n: 'Internationalisation',
      advanced: 'Extensions avancées',
      advancedDesc: 'Mathématiques, système et autres'
    },

    extensions: {
      // Core
      opcache: 'OPcache - Cache de bytecode pour améliorer les performances',
      tokenizer: 'Tokenizer - Analyseur de code PHP',
      filter: 'Filter - Validation et filtrage des entrées',
      ctype: 'Ctype - Vérification des types de caractères',
      cli: 'CLI - Interface en ligne de commande',
      session: 'Session - Gestion des sessions',
      phar: 'Phar - Archive PHP',

      // Database
      pdo: 'PDO - Couche d\'abstraction de base de données',
      pdo_mysql: 'PDO MySQL - Pilote MySQL/MariaDB',
      mysqli: 'MySQLi - Interface MySQL améliorée',
      pdo_sqlite: 'PDO SQLite - Pilote SQLite',

      // Network
      curl: 'cURL - Bibliothèque client HTTP',
      openssl: 'OpenSSL - Cryptographie SSL/TLS',
      ftp: 'FTP - Client File Transfer Protocol',
      sockets: 'Sockets - Communication réseau bas niveau',

      // Images
      gd: 'GD - Manipulation d\'images (PNG, JPEG, WebP, FreeType)',
      exif: 'EXIF - Lecture des métadonnées d\'images',

      // XML
      dom: 'DOM - Modèle objet de document XML',
      xml: 'XML Parser - Analyse XML de base',
      simplexml: 'SimpleXML - Interface XML simplifiée',

      // Compression
      zip: 'Zip - Support des archives ZIP',
      zlib: 'Zlib - Compression gzip',
      bz2: 'BZip2 - Compression bzip2',

      // I18n
      mbstring: 'Mbstring - Fonctions de chaînes multioctets',
      intl: 'Intl - Internationalisation (ICU)',
      gettext: 'Gettext - Texte multilingue',
      iconv: 'Iconv - Conversion d\'encodage de caractères',

      // Advanced
      bcmath: 'BCMath - Mathématiques en précision arbitraire',
      gmp: 'GMP - GNU Multiple Precision',
      sodium: 'Sodium - Cryptographie moderne',
      fileinfo: 'Fileinfo - Détection du type de fichier',
      posix: 'POSIX - Fonctions système Unix',
      pcntl: 'PCNTL - Contrôle de processus (fork, signaux)'
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
