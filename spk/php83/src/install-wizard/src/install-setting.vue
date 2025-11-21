<template>
  <pkg-center-step-content>
    <v-form syno-id="form">
      <v-form-item syno-id="form-item-intro" hide-label textonly>
        <v-rich-text :text="t.intro" />
      </v-form-item>

      <!-- Global select/deselect buttons -->
      <v-form-item syno-id="form-item-global-buttons" hide-label>
        <v-button syno-id="btn-select-all" @click="selectAll">{{ t.selectAll }}</v-button>
        <v-button syno-id="btn-deselect-all" @click="deselectAll" style="margin-left: 10px;">{{ t.deselectAll }}</v-button>
      </v-form-item>

      <!-- Core Extensions -->
      <v-form-item syno-id="form-item-core-title" hide-label textonly>
        <b>{{ t.categories.core }}</b> - {{ t.categories.coreDesc }}
      </v-form-item>
      <v-form-item syno-id="form-item-core" hide-label :indent="1">
        <v-checkbox syno-id="cb-cli" v-model="ext_cli" disabled>{{ t.extensions.cli }} ({{ t.native }})</v-checkbox>
        <v-checkbox syno-id="cb-session" v-model="ext_session" disabled>{{ t.extensions.session }} ({{ t.native }})</v-checkbox>
        <v-checkbox syno-id="cb-phar" v-model="ext_phar" disabled>{{ t.extensions.phar }} ({{ t.native }})</v-checkbox>
        <v-checkbox syno-id="cb-opcache" v-model="ext_opcache">{{ t.extensions.opcache }}</v-checkbox>
        <v-checkbox syno-id="cb-tokenizer" v-model="ext_tokenizer">{{ t.extensions.tokenizer }}</v-checkbox>
        <v-checkbox syno-id="cb-filter" v-model="ext_filter">{{ t.extensions.filter }}</v-checkbox>
        <v-checkbox syno-id="cb-ctype" v-model="ext_ctype">{{ t.extensions.ctype }}</v-checkbox>
      </v-form-item>

      <!-- Database Extensions -->
      <v-form-item syno-id="form-item-db-title" hide-label textonly>
        <b>{{ t.categories.database }}</b> - {{ t.categories.databaseDesc }}
      </v-form-item>
      <v-form-item syno-id="form-item-db" hide-label :indent="1">
        <v-checkbox syno-id="cb-pdo" v-model="ext_pdo">{{ t.extensions.pdo }}</v-checkbox>
        <v-checkbox syno-id="cb-pdo-mysql" v-model="ext_pdo_mysql">{{ t.extensions.pdo_mysql }}</v-checkbox>
        <v-checkbox syno-id="cb-mysqli" v-model="ext_mysqli">{{ t.extensions.mysqli }}</v-checkbox>
        <v-checkbox syno-id="cb-pdo-sqlite" v-model="ext_pdo_sqlite">{{ t.extensions.pdo_sqlite }}</v-checkbox>
      </v-form-item>

      <!-- Web & Network -->
      <v-form-item syno-id="form-item-net-title" hide-label textonly>
        <b>{{ t.categories.network }}</b> - {{ t.categories.networkDesc }}
      </v-form-item>
      <v-form-item syno-id="form-item-net" hide-label :indent="1">
        <v-checkbox syno-id="cb-curl" v-model="ext_curl">{{ t.extensions.curl }}</v-checkbox>
        <v-checkbox syno-id="cb-openssl" v-model="ext_openssl">{{ t.extensions.openssl }}</v-checkbox>
        <v-checkbox syno-id="cb-ftp" v-model="ext_ftp">{{ t.extensions.ftp }}</v-checkbox>
        <v-checkbox syno-id="cb-sockets" v-model="ext_sockets">{{ t.extensions.sockets }}</v-checkbox>
      </v-form-item>

      <!-- Images -->
      <v-form-item syno-id="form-item-img-title" hide-label textonly>
        <b>{{ t.categories.images }}</b> - {{ t.categories.imagesDesc }}
      </v-form-item>
      <v-form-item syno-id="form-item-img" hide-label :indent="1">
        <v-checkbox syno-id="cb-gd" v-model="ext_gd">{{ t.extensions.gd }}</v-checkbox>
        <v-checkbox syno-id="cb-exif" v-model="ext_exif">{{ t.extensions.exif }}</v-checkbox>
      </v-form-item>

      <!-- XML Processing -->
      <v-form-item syno-id="form-item-xml-title" hide-label textonly>
        <b>{{ t.categories.xml }}</b>
      </v-form-item>
      <v-form-item syno-id="form-item-xml" hide-label :indent="1">
        <v-checkbox syno-id="cb-dom" v-model="ext_dom">{{ t.extensions.dom }}</v-checkbox>
        <v-checkbox syno-id="cb-xml" v-model="ext_xml">{{ t.extensions.xml }}</v-checkbox>
        <v-checkbox syno-id="cb-simplexml" v-model="ext_simplexml">{{ t.extensions.simplexml }}</v-checkbox>
      </v-form-item>

      <!-- Compression -->
      <v-form-item syno-id="form-item-zip-title" hide-label textonly>
        <b>{{ t.categories.compression }}</b>
      </v-form-item>
      <v-form-item syno-id="form-item-zip" hide-label :indent="1">
        <v-checkbox syno-id="cb-zip" v-model="ext_zip">{{ t.extensions.zip }}</v-checkbox>
        <v-checkbox syno-id="cb-zlib" v-model="ext_zlib">{{ t.extensions.zlib }}</v-checkbox>
        <v-checkbox syno-id="cb-bz2" v-model="ext_bz2">{{ t.extensions.bz2 }}</v-checkbox>
      </v-form-item>

      <!-- Internationalization -->
      <v-form-item syno-id="form-item-i18n-title" hide-label textonly>
        <b>{{ t.categories.i18n }}</b>
      </v-form-item>
      <v-form-item syno-id="form-item-i18n" hide-label :indent="1">
        <v-checkbox syno-id="cb-mbstring" v-model="ext_mbstring">{{ t.extensions.mbstring }}</v-checkbox>
        <v-checkbox syno-id="cb-intl" v-model="ext_intl">{{ t.extensions.intl }}</v-checkbox>
        <v-checkbox syno-id="cb-gettext" v-model="ext_gettext">{{ t.extensions.gettext }}</v-checkbox>
        <v-checkbox syno-id="cb-iconv" v-model="ext_iconv">{{ t.extensions.iconv }}</v-checkbox>
      </v-form-item>

      <!-- Advanced -->
      <v-form-item syno-id="form-item-adv-title" hide-label textonly>
        <b>{{ t.categories.advanced }}</b> - {{ t.categories.advancedDesc }}
      </v-form-item>
      <v-form-item syno-id="form-item-adv" hide-label :indent="1">
        <v-checkbox syno-id="cb-bcmath" v-model="ext_bcmath">{{ t.extensions.bcmath }}</v-checkbox>
        <v-checkbox syno-id="cb-gmp" v-model="ext_gmp">{{ t.extensions.gmp }}</v-checkbox>
        <v-checkbox syno-id="cb-sodium" v-model="ext_sodium">{{ t.extensions.sodium }}</v-checkbox>
        <v-checkbox syno-id="cb-fileinfo" v-model="ext_fileinfo">{{ t.extensions.fileinfo }}</v-checkbox>
        <v-checkbox syno-id="cb-posix" v-model="ext_posix">{{ t.extensions.posix }}</v-checkbox>
        <v-checkbox syno-id="cb-pcntl" v-model="ext_pcntl">{{ t.extensions.pcntl }}</v-checkbox>
      </v-form-item>

    </v-form>
  </pkg-center-step-content>
</template>

<script>
import { defineComponent, ref } from 'vue';
import { useI18n } from './i18n';

export default defineComponent({
  props: {
    ...SYNO.SDS.PkgManApp.Custom.useHook.props,
  },
  setup(props) {
    const { getNext, checkState } = SYNO.SDS.PkgManApp.Custom.useHook(props);
    const { t } = useI18n();

    // Native extensions (always enabled, displayed as disabled checkboxes)
    const ext_cli = ref(true);
    const ext_session = ref(true);
    const ext_phar = ref(true);

    // Core extensions (recommended by default)
    const ext_opcache = ref(true);
    const ext_tokenizer = ref(true);
    const ext_filter = ref(true);
    const ext_ctype = ref(true);

    // Database extensions
    const ext_pdo = ref(true);
    const ext_pdo_mysql = ref(true);
    const ext_mysqli = ref(true);
    const ext_pdo_sqlite = ref(false);

    // Web & Network
    const ext_curl = ref(true);
    const ext_openssl = ref(true);
    const ext_ftp = ref(false);
    const ext_sockets = ref(false);

    // Images
    const ext_gd = ref(true);
    const ext_exif = ref(true);

    // XML
    const ext_dom = ref(true);
    const ext_xml = ref(true);
    const ext_simplexml = ref(true);

    // Compression
    const ext_zip = ref(true);
    const ext_zlib = ref(true);
    const ext_bz2 = ref(false);

    // Internationalization
    const ext_mbstring = ref(true);
    const ext_intl = ref(true);
    const ext_gettext = ref(false);
    const ext_iconv = ref(true);

    // Advanced
    const ext_bcmath = ref(false);
    const ext_gmp = ref(false);
    const ext_sodium = ref(true);
    const ext_fileinfo = ref(true);
    const ext_posix = ref(false);
    const ext_pcntl = ref(false);

    // Select/Deselect all functions
    const selectableExtensions = [
      ext_opcache, ext_tokenizer, ext_filter, ext_ctype,
      ext_pdo, ext_pdo_mysql, ext_mysqli, ext_pdo_sqlite,
      ext_curl, ext_openssl, ext_ftp, ext_sockets,
      ext_gd, ext_exif,
      ext_dom, ext_xml, ext_simplexml,
      ext_zip, ext_zlib, ext_bz2,
      ext_mbstring, ext_intl, ext_gettext, ext_iconv,
      ext_bcmath, ext_gmp, ext_sodium, ext_fileinfo, ext_posix, ext_pcntl
    ];

    const selectAll = () => {
      selectableExtensions.forEach(ext => ext.value = true);
    };

    const deselectAll = () => {
      selectableExtensions.forEach(ext => ext.value = false);
    };

    const headline = t.title;

    const getValues = () => {
      return {
        // Native extensions (always true, but not configurable)
        pkgwizard_ext_cli: true,
        pkgwizard_ext_session: true,
        pkgwizard_ext_phar: true,
        // Core
        pkgwizard_ext_opcache: ext_opcache.value,
        pkgwizard_ext_tokenizer: ext_tokenizer.value,
        pkgwizard_ext_filter: ext_filter.value,
        pkgwizard_ext_ctype: ext_ctype.value,
        // Database
        pkgwizard_ext_pdo: ext_pdo.value,
        pkgwizard_ext_pdo_mysql: ext_pdo_mysql.value,
        pkgwizard_ext_mysqli: ext_mysqli.value,
        pkgwizard_ext_pdo_sqlite: ext_pdo_sqlite.value,
        // Network
        pkgwizard_ext_curl: ext_curl.value,
        pkgwizard_ext_openssl: ext_openssl.value,
        pkgwizard_ext_ftp: ext_ftp.value,
        pkgwizard_ext_sockets: ext_sockets.value,
        // Images
        pkgwizard_ext_gd: ext_gd.value,
        pkgwizard_ext_exif: ext_exif.value,
        // XML
        pkgwizard_ext_dom: ext_dom.value,
        pkgwizard_ext_xml: ext_xml.value,
        pkgwizard_ext_simplexml: ext_simplexml.value,
        // Compression
        pkgwizard_ext_zip: ext_zip.value,
        pkgwizard_ext_zlib: ext_zlib.value,
        pkgwizard_ext_bz2: ext_bz2.value,
        // I18n
        pkgwizard_ext_mbstring: ext_mbstring.value,
        pkgwizard_ext_intl: ext_intl.value,
        pkgwizard_ext_gettext: ext_gettext.value,
        pkgwizard_ext_iconv: ext_iconv.value,
        // Advanced
        pkgwizard_ext_bcmath: ext_bcmath.value,
        pkgwizard_ext_gmp: ext_gmp.value,
        pkgwizard_ext_sodium: ext_sodium.value,
        pkgwizard_ext_fileinfo: ext_fileinfo.value,
        pkgwizard_ext_posix: ext_posix.value,
        pkgwizard_ext_pcntl: ext_pcntl.value,
      };
    };

    return {
      getNext,
      checkState,
      headline,
      t,
      getValues,
      selectAll,
      deselectAll,
      // Native
      ext_cli,
      ext_session,
      ext_phar,
      // Core
      ext_opcache,
      ext_tokenizer,
      ext_filter,
      ext_ctype,
      // Database
      ext_pdo,
      ext_pdo_mysql,
      ext_mysqli,
      ext_pdo_sqlite,
      // Network
      ext_curl,
      ext_openssl,
      ext_ftp,
      ext_sockets,
      // Images
      ext_gd,
      ext_exif,
      // XML
      ext_dom,
      ext_xml,
      ext_simplexml,
      // Compression
      ext_zip,
      ext_zlib,
      ext_bz2,
      // I18n
      ext_mbstring,
      ext_intl,
      ext_gettext,
      ext_iconv,
      // Advanced
      ext_bcmath,
      ext_gmp,
      ext_sodium,
      ext_fileinfo,
      ext_posix,
      ext_pcntl,
    };
  },
});
</script>
