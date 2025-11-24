#!/usr/bin/env python3
"""
generate-wizard.py - Generate Vue.js wizard from extensions.json

This script reads the extensions.json configuration file and generates
a complete Vue.js installation wizard with all extensions and i18n file.
"""

import json
import sys
import re
from pathlib import Path

# Define color codes
class Colors:
    GREEN = '\033[0;32m'
    YELLOW = '\033[1;33m'
    RED = '\033[0;31m'
    NC = '\033[0m'  # No Color

def get_php_version(project_root):
    """Extract PHP version from build-spk.sh"""
    build_script = project_root / 'scripts' / 'build-spk.sh'
    with open(build_script, 'r') as f:
        content = f.read()
        match = re.search(r'PKG_VERSION="([^"]+)"', content)
        if match:
            return match.group(1)
    return "8.3.28"  # Fallback

def load_extensions_json(project_root):
    """Load extensions from extensions.json"""
    json_path = project_root / 'spk' / 'php83' / 'conf' / 'extensions.json'

    with open(json_path, 'r', encoding='utf-8') as f:
        data = json.load(f)

    return data['categories']

def generate_vue_template(categories):
    """Generate Vue.js template section"""
    template_parts = []
    template_parts.append('<template>')
    template_parts.append('  <pkg-center-step-content>')
    template_parts.append('    <v-form syno-id="form">')

    # Intro
    template_parts.append('      <v-form-item syno-id="form-item-intro" hide-label textonly>')
    template_parts.append('        <v-rich-text :text="t.intro" />')
    template_parts.append('      </v-form-item>')
    template_parts.append('')

    # Global buttons
    template_parts.append('      <!-- Global select/deselect buttons -->')
    template_parts.append('      <v-form-item syno-id="form-item-global-buttons" hide-label>')
    template_parts.append('        <v-button syno-id="btn-select-all" @click="selectAll">{{ t.selectAll }}</v-button>')
    template_parts.append('        <v-button syno-id="btn-deselect-all" @click="deselectAll" style="margin-left: 10px;">{{ t.deselectAll }}</v-button>')
    template_parts.append('      </v-form-item>')
    template_parts.append('')

    # Generate sections for each category
    for category_id, category_data in categories.items():
        category_name = category_data['name']
        category_desc = category_data.get('description', '')
        extensions = category_data['extensions']

        # Category title
        template_parts.append(f'      <!-- {category_name} -->')
        template_parts.append(f'      <v-form-item syno-id="form-item-{category_id}-title" hide-label textonly>')
        if category_desc:
            template_parts.append(f'        <b>{{{{ t.categories.{category_id} }}}}</b> - {category_desc}')
        else:
            template_parts.append(f'        <b>{{{{ t.categories.{category_id} }}}}</b>')
        template_parts.append('      </v-form-item>')

        # Extensions
        template_parts.append(f'      <v-form-item syno-id="form-item-{category_id}" hide-label :indent="1">')
        for ext_id, ext_data in extensions.items():
            required = ext_data.get('required', False)
            disabled_attr = ' disabled' if required else ''
            native_label = ' ({{ t.native }})' if required else ''
            template_parts.append(f'        <v-checkbox syno-id="cb-{ext_id}" v-model="ext_{ext_id}"{disabled_attr}>{{{{ t.extensions.{ext_id} }}}}{native_label}</v-checkbox>')
        template_parts.append('      </v-form-item>')
        template_parts.append('')

    template_parts.append('    </v-form>')
    template_parts.append('  </pkg-center-step-content>')
    template_parts.append('</template>')

    return '\n'.join(template_parts)

def generate_script_section(categories):
    """Generate Vue.js script section"""
    script_parts = []
    script_parts.append('<script>')
    script_parts.append("import { defineComponent, ref } from 'vue';")
    script_parts.append("import { useI18n } from './i18n';")
    script_parts.append('')
    script_parts.append('export default defineComponent({')
    script_parts.append('  props: {')
    script_parts.append('    ...SYNO.SDS.PkgManApp.Custom.useHook.props,')
    script_parts.append('  },')
    script_parts.append('  setup(props) {')
    script_parts.append('    const { getNext, checkState } = SYNO.SDS.PkgManApp.Custom.useHook(props);')
    script_parts.append('    const { t } = useI18n();')
    script_parts.append('')

    #Generate extension refs
    all_extensions = []
    selectable_extensions = []

    for category_id, category_data in categories.items():
        script_parts.append(f'    // {category_data["name"]}')
        for ext_id, ext_data in category_data['extensions'].items():
            default_enabled = ext_data.get('enabled_by_default', False)
            required = ext_data.get('required', False)
            default_value = 'true' if (default_enabled or required) else 'false'
            script_parts.append(f'    const ext_{ext_id} = ref({default_value});')
            all_extensions.append(ext_id)
            if not required:
                selectable_extensions.append(ext_id)
        script_parts.append('')

    # Selectable extensions array
    script_parts.append('    // Select/Deselect all functions')
    script_parts.append('    const selectableExtensions = [')
    script_parts.append('      ' + ', '.join([f'ext_{ext}' for ext in selectable_extensions]))
    script_parts.append('    ];')
    script_parts.append('')

    # Select/Deselect functions
    script_parts.append('    const selectAll = () => {')
    script_parts.append('      selectableExtensions.forEach(ext => ext.value = true);')
    script_parts.append('    };')
    script_parts.append('')
    script_parts.append('    const deselectAll = () => {')
    script_parts.append('      selectableExtensions.forEach(ext => ext.value = false);')
    script_parts.append('    };')
    script_parts.append('')

    # Headline
    script_parts.append('    const headline = t.title;')
    script_parts.append('')

    # getValues function
    script_parts.append('    const getValues = () => {')
    script_parts.append('      return {')
    for ext_id in all_extensions:
        script_parts.append(f'        pkgwizard_ext_{ext_id}: ext_{ext_id}.value,')
    script_parts.append('      };')
    script_parts.append('    };')
    script_parts.append('')

    # Return statement
    script_parts.append('    return {')
    script_parts.append('      getNext,')
    script_parts.append('      checkState,')
    script_parts.append('      headline,')
    script_parts.append('      t,')
    script_parts.append('      getValues,')
    script_parts.append('      selectAll,')
    script_parts.append('      deselectAll,')
    for ext_id in all_extensions:
        script_parts.append(f'      ext_{ext_id},')
    script_parts.append('    };')
    script_parts.append('  },')
    script_parts.append('});')
    script_parts.append('</script>')

    return '\n'.join(script_parts)

def generate_i18n_file(categories, php_version, total_extensions):
    """Generate i18n.js file with translations"""

    # French translations for categories
    category_translations_fr = {
        'core': 'Extensions de base',
        'math': 'Mathématiques',
        'xml': 'Traitement XML',
        'databases': 'Extensions de base de données',
        'network': 'Réseau et protocoles',
        'compression': 'Compression et archives',
        'images': 'Traitement d\'images',
        'io': 'Fichiers et sessions',
        'system': 'Système et processus',
        'i18n': 'Internationalisation'
    }

    # French translations for extensions
    extension_translations_fr = {
        'opcache': 'OPcache - Cache de bytecode pour améliorer les performances',
        'tokenizer': 'Tokenizer - Analyseur de code PHP',
        'filter': 'Filter - Validation et filtrage des entrées',
        'ctype': 'Ctype - Vérification des types de caractères',
        'bcmath': 'BCMath - Mathématiques en précision arbitraire',
        'gmp': 'GMP - GNU Multiple Precision',
        'xml': 'XML Parser - Analyse XML de base',
        'dom': 'DOM - Modèle objet de document XML',
        'simplexml': 'SimpleXML - Interface XML simplifiée',
        'xmlreader': 'XMLReader - Analyseur XML Pull',
        'xmlwriter': 'XMLWriter - Génération de documents XML',
        'soap': 'SOAP - Services web SOAP',
        'pdo': 'PDO - Couche d\'abstraction de base de données',
        'mysqli': 'MySQLi - Interface MySQL améliorée',
        'mysqlnd': 'MySQL Native Driver - Pilote MySQL natif',
        'pdo_mysql': 'PDO MySQL - Pilote MySQL/MariaDB',
        'sqlite3': 'SQLite3 - Support de base de données SQLite 3',
        'pdo_sqlite': 'PDO SQLite - Pilote SQLite',
        'dba': 'DBA - Couche d\'abstraction de base de données',
        'curl': 'cURL - Bibliothèque client HTTP',
        'openssl': 'OpenSSL - Cryptographie SSL/TLS',
        'ftp': 'FTP - Client File Transfer Protocol',
        'sockets': 'Sockets - Communication réseau bas niveau',
        'zlib': 'Zlib - Compression gzip',
        'bz2': 'BZip2 - Compression bzip2',
        'phar': 'Phar - Support des archives PHP',
        'gd': 'GD - Manipulation d\'images (PNG, JPEG, WebP, FreeType)',
        'exif': 'EXIF - Lecture des métadonnées d\'images',
        'fileinfo': 'Fileinfo - Détection du type de fichier',
        'session': 'Session - Gestion des sessions',
        'posix': 'POSIX - Fonctions système Unix',
        'pcntl': 'PCNTL - Contrôle de processus (fork, signaux)',
        'shmop': 'Shmop - Opérations de mémoire partagée',
        'sysvmsg': 'System V Messages - Files de messages System V',
        'sysvsem': 'System V Semaphores - Sémaphores System V',
        'sysvshm': 'System V Shared Memory - Mémoire partagée System V',
        'gettext': 'Gettext - Texte multilingue',
        'iconv': 'Iconv - Conversion d\'encodage de caractères',
        'intl': 'Intl - Internationalisation (ICU)',
        'calendar': 'Calendar - Fonctions de conversion de calendrier'
    }

    i18n_parts = []
    i18n_parts.append('// Internationalization for PHP 8.3 wizard')
    i18n_parts.append('// Auto-generated from extensions.json - DO NOT EDIT MANUALLY')
    i18n_parts.append('')
    i18n_parts.append('const translations = {')
    i18n_parts.append('  en: {')
    i18n_parts.append('    title: \'PHP 8.3 Extension Configuration\',')
    i18n_parts.append(f'    intro: \'PHP {php_version} has been compiled with {total_extensions} extensions. Select which extensions to enable. You can modify these settings later in Package Center.\',')
    i18n_parts.append('    selectAll: \'Select All\',')
    i18n_parts.append('    deselectAll: \'Deselect All\',')
    i18n_parts.append('    native: \'native\',')
    i18n_parts.append('')
    i18n_parts.append('    categories: {')

    # Generate category translations (English)
    for cat_id, cat_data in categories.items():
        i18n_parts.append(f'      {cat_id}: \'{cat_data["name"]}\',')
    i18n_parts.append('    },')
    i18n_parts.append('')
    i18n_parts.append('    extensions: {')

    # Generate extension translations (English)
    for cat_id, cat_data in categories.items():
        i18n_parts.append(f'      // {cat_data["name"]}')
        for ext_id, ext_data in cat_data['extensions'].items():
            desc = ext_data['description']
            i18n_parts.append(f'      {ext_id}: \'{ext_data["name"]} - {desc}\',')
        i18n_parts.append('')

    i18n_parts.append('    }')
    i18n_parts.append('  },')
    i18n_parts.append('')
    i18n_parts.append('  fre: {')
    i18n_parts.append('    title: \'Configuration des Extensions PHP 8.3\',')
    i18n_parts.append(f'    intro: \'PHP {php_version} a été compilé avec {total_extensions} extensions. Sélectionnez les extensions à activer. Vous pourrez modifier ces paramètres ultérieurement dans le Centre de paquets.\',')
    i18n_parts.append('    selectAll: \'Tout sélectionner\',')
    i18n_parts.append('    deselectAll: \'Tout désélectionner\',')
    i18n_parts.append('    native: \'natif\',')
    i18n_parts.append('')
    i18n_parts.append('    categories: {')

    # Generate category translations (French)
    for cat_id, cat_data in categories.items():
        fr_name = category_translations_fr.get(cat_id, cat_data['name'])
        fr_name_escaped = fr_name.replace("'", "\'")
        i18n_parts.append(f'      {cat_id}: \'{fr_name_escaped}\',')
    i18n_parts.append('    },')
    i18n_parts.append('')
    i18n_parts.append('    extensions: {')

    # Generate extension translations (French)
    for cat_id, cat_data in categories.items():
        fr_cat_name = category_translations_fr.get(cat_id, cat_data["name"])
        fr_cat_name_escaped = fr_cat_name.replace("'", "\'")
        i18n_parts.append(f'      // {fr_cat_name_escaped}')
        for ext_id, ext_data in cat_data['extensions'].items():
            fr_desc = extension_translations_fr.get(ext_id, f'{ext_data["name"]} - {ext_data["description"]}')
            fr_desc_escaped = fr_desc.replace("'", "\'")
            i18n_parts.append(f'      {ext_id}: \'{fr_desc_escaped}\',')
        i18n_parts.append('')

    i18n_parts.append('    }')
    i18n_parts.append('  }')
    i18n_parts.append('};')
    i18n_parts.append('')
    i18n_parts.append('// Detect system language from DSM')
    i18n_parts.append('export function getSystemLanguage() {')
    i18n_parts.append('  // Try to get language from DSM global variable')
    i18n_parts.append('  if (typeof _S === \'function\') {')
    i18n_parts.append('    const lang = _S(\'lang\');')
    i18n_parts.append('    if (lang && translations[lang]) {')
    i18n_parts.append('      return lang;')
    i18n_parts.append('    }')
    i18n_parts.append('  }')
    i18n_parts.append('')
    i18n_parts.append('  // Fallback to browser language')
    i18n_parts.append('  const browserLang = navigator.language || navigator.userLanguage;')
    i18n_parts.append('  if (browserLang.startsWith(\'fr\')) return \'fre\';')
    i18n_parts.append('')
    i18n_parts.append('  return \'en\'; // Default to English')
    i18n_parts.append('}')
    i18n_parts.append('')
    i18n_parts.append('// Get translation function')
    i18n_parts.append('export function useI18n() {')
    i18n_parts.append('  const lang = getSystemLanguage();')
    i18n_parts.append('  const t = translations[lang] || translations.en;')
    i18n_parts.append('')
    i18n_parts.append('  return {')
    i18n_parts.append('    t,')
    i18n_parts.append('    lang')
    i18n_parts.append('  };')
    i18n_parts.append('}')
    i18n_parts.append('')

    return '\n'.join(i18n_parts)

def main():
    # Get project root
    script_dir = Path(__file__).parent.resolve()
    project_root = script_dir.parent

    print(f"{Colors.GREEN}[INFO]{Colors.NC} Generating Vue.js wizard from extensions.json...")

    # Get PHP version
    php_version = get_php_version(project_root)
    print(f"{Colors.GREEN}[INFO]{Colors.NC} PHP Version: {php_version}")

    # Load extensions
    try:
        categories = load_extensions_json(project_root)
        total_extensions = sum(len(cat['extensions']) for cat in categories.values())
        print(f"{Colors.GREEN}[INFO]{Colors.NC} Loaded {total_extensions} extensions from {len(categories)} categories")
    except Exception as e:
        print(f"{Colors.RED}[ERROR]{Colors.NC} Failed to load extensions.json: {e}")
        sys.exit(1)

    # Generate i18n.js file
    i18n_content = generate_i18n_file(categories, php_version, total_extensions)
    i18n_path = project_root / 'spk' / 'php83' / 'src' / 'install-wizard' / 'src' / 'i18n.js'

    try:
        with open(i18n_path, 'w', encoding='utf-8') as f:
            f.write(i18n_content)
        print(f"{Colors.GREEN}[SUCCESS]{Colors.NC} Generated: {i18n_path.relative_to(project_root)}")
    except Exception as e:
        print(f"{Colors.RED}[ERROR]{Colors.NC} Failed to write i18n.js: {e}")
        sys.exit(1)

    # Generate Vue.js file
    template = generate_vue_template(categories)
    script = generate_script_section(categories)

    vue_content = f"{template}\n\n{script}\n"

    # Write to file
    output_path = project_root / 'spk' / 'php83' / 'src' / 'install-wizard' / 'src' / 'install-setting.vue'

    try:
        with open(output_path, 'w', encoding='utf-8') as f:
            f.write(vue_content)
        print(f"{Colors.GREEN}[SUCCESS]{Colors.NC} Generated: {output_path.relative_to(project_root)}")
        print(f"{Colors.YELLOW}[NEXT]{Colors.NC} Run 'cd spk/php83/src/install-wizard && npm run build' to rebuild the wizard")
    except Exception as e:
        print(f"{Colors.RED}[ERROR]{Colors.NC} Failed to write Vue file: {e}")
        sys.exit(1)

if __name__ == '__main__':
    main()
