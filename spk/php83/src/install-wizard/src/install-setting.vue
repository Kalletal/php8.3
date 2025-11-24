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
        <b>{{ t.categories.core }}</b>
      </v-form-item>
      <v-form-item syno-id="form-item-core" hide-label :indent="1">
        <v-checkbox syno-id="cb-opcache" v-model="ext_opcache" disabled>{{ t.extensions.opcache }} ({{ t.native }})</v-checkbox>
        <v-checkbox syno-id="cb-tokenizer" v-model="ext_tokenizer">{{ t.extensions.tokenizer }}</v-checkbox>
        <v-checkbox syno-id="cb-filter" v-model="ext_filter">{{ t.extensions.filter }}</v-checkbox>
        <v-checkbox syno-id="cb-ctype" v-model="ext_ctype">{{ t.extensions.ctype }}</v-checkbox>
      </v-form-item>

      <!-- Mathematics -->
      <v-form-item syno-id="form-item-math-title" hide-label textonly>
        <b>{{ t.categories.math }}</b>
      </v-form-item>
      <v-form-item syno-id="form-item-math" hide-label :indent="1">
        <v-checkbox syno-id="cb-bcmath" v-model="ext_bcmath">{{ t.extensions.bcmath }}</v-checkbox>
      </v-form-item>

      <!-- XML & Text Processing -->
      <v-form-item syno-id="form-item-xml-title" hide-label textonly>
        <b>{{ t.categories.xml }}</b>
      </v-form-item>
      <v-form-item syno-id="form-item-xml" hide-label :indent="1">
        <v-checkbox syno-id="cb-xml" v-model="ext_xml">{{ t.extensions.xml }}</v-checkbox>
        <v-checkbox syno-id="cb-dom" v-model="ext_dom">{{ t.extensions.dom }}</v-checkbox>
        <v-checkbox syno-id="cb-simplexml" v-model="ext_simplexml">{{ t.extensions.simplexml }}</v-checkbox>
        <v-checkbox syno-id="cb-xmlreader" v-model="ext_xmlreader">{{ t.extensions.xmlreader }}</v-checkbox>
        <v-checkbox syno-id="cb-xmlwriter" v-model="ext_xmlwriter">{{ t.extensions.xmlwriter }}</v-checkbox>
        <v-checkbox syno-id="cb-soap" v-model="ext_soap">{{ t.extensions.soap }}</v-checkbox>
      </v-form-item>

      <!-- Database Extensions -->
      <v-form-item syno-id="form-item-databases-title" hide-label textonly>
        <b>{{ t.categories.databases }}</b>
      </v-form-item>
      <v-form-item syno-id="form-item-databases" hide-label :indent="1">
        <v-checkbox syno-id="cb-pdo" v-model="ext_pdo">{{ t.extensions.pdo }}</v-checkbox>
        <v-checkbox syno-id="cb-mysqli" v-model="ext_mysqli">{{ t.extensions.mysqli }}</v-checkbox>
        <v-checkbox syno-id="cb-mysqlnd" v-model="ext_mysqlnd">{{ t.extensions.mysqlnd }}</v-checkbox>
        <v-checkbox syno-id="cb-pdo_mysql" v-model="ext_pdo_mysql">{{ t.extensions.pdo_mysql }}</v-checkbox>
        <v-checkbox syno-id="cb-sqlite3" v-model="ext_sqlite3">{{ t.extensions.sqlite3 }}</v-checkbox>
        <v-checkbox syno-id="cb-pdo_sqlite" v-model="ext_pdo_sqlite">{{ t.extensions.pdo_sqlite }}</v-checkbox>
        <v-checkbox syno-id="cb-dba" v-model="ext_dba">{{ t.extensions.dba }}</v-checkbox>
      </v-form-item>

      <!-- Network & Protocols -->
      <v-form-item syno-id="form-item-network-title" hide-label textonly>
        <b>{{ t.categories.network }}</b>
      </v-form-item>
      <v-form-item syno-id="form-item-network" hide-label :indent="1">
        <v-checkbox syno-id="cb-curl" v-model="ext_curl">{{ t.extensions.curl }}</v-checkbox>
        <v-checkbox syno-id="cb-openssl" v-model="ext_openssl">{{ t.extensions.openssl }}</v-checkbox>
        <v-checkbox syno-id="cb-ftp" v-model="ext_ftp">{{ t.extensions.ftp }}</v-checkbox>
        <v-checkbox syno-id="cb-sockets" v-model="ext_sockets">{{ t.extensions.sockets }}</v-checkbox>
      </v-form-item>

      <!-- Compression & Archives -->
      <v-form-item syno-id="form-item-compression-title" hide-label textonly>
        <b>{{ t.categories.compression }}</b>
      </v-form-item>
      <v-form-item syno-id="form-item-compression" hide-label :indent="1">
        <v-checkbox syno-id="cb-zlib" v-model="ext_zlib">{{ t.extensions.zlib }}</v-checkbox>
        <v-checkbox syno-id="cb-bz2" v-model="ext_bz2">{{ t.extensions.bz2 }}</v-checkbox>
        <v-checkbox syno-id="cb-phar" v-model="ext_phar">{{ t.extensions.phar }}</v-checkbox>
      </v-form-item>

      <!-- Image Processing -->
      <v-form-item syno-id="form-item-images-title" hide-label textonly>
        <b>{{ t.categories.images }}</b>
      </v-form-item>
      <v-form-item syno-id="form-item-images" hide-label :indent="1">
        <v-checkbox syno-id="cb-gd" v-model="ext_gd">{{ t.extensions.gd }}</v-checkbox>
        <v-checkbox syno-id="cb-exif" v-model="ext_exif">{{ t.extensions.exif }}</v-checkbox>
      </v-form-item>

      <!-- File I/O & Sessions -->
      <v-form-item syno-id="form-item-io-title" hide-label textonly>
        <b>{{ t.categories.io }}</b>
      </v-form-item>
      <v-form-item syno-id="form-item-io" hide-label :indent="1">
        <v-checkbox syno-id="cb-fileinfo" v-model="ext_fileinfo">{{ t.extensions.fileinfo }}</v-checkbox>
        <v-checkbox syno-id="cb-session" v-model="ext_session">{{ t.extensions.session }}</v-checkbox>
      </v-form-item>

      <!-- System & Process -->
      <v-form-item syno-id="form-item-system-title" hide-label textonly>
        <b>{{ t.categories.system }}</b>
      </v-form-item>
      <v-form-item syno-id="form-item-system" hide-label :indent="1">
        <v-checkbox syno-id="cb-posix" v-model="ext_posix">{{ t.extensions.posix }}</v-checkbox>
        <v-checkbox syno-id="cb-pcntl" v-model="ext_pcntl">{{ t.extensions.pcntl }}</v-checkbox>
        <v-checkbox syno-id="cb-shmop" v-model="ext_shmop">{{ t.extensions.shmop }}</v-checkbox>
        <v-checkbox syno-id="cb-sysvmsg" v-model="ext_sysvmsg">{{ t.extensions.sysvmsg }}</v-checkbox>
        <v-checkbox syno-id="cb-sysvsem" v-model="ext_sysvsem">{{ t.extensions.sysvsem }}</v-checkbox>
        <v-checkbox syno-id="cb-sysvshm" v-model="ext_sysvshm">{{ t.extensions.sysvshm }}</v-checkbox>
      </v-form-item>

      <!-- Internationalization -->
      <v-form-item syno-id="form-item-i18n-title" hide-label textonly>
        <b>{{ t.categories.i18n }}</b>
      </v-form-item>
      <v-form-item syno-id="form-item-i18n" hide-label :indent="1">
        <v-checkbox syno-id="cb-gettext" v-model="ext_gettext">{{ t.extensions.gettext }}</v-checkbox>
        <v-checkbox syno-id="cb-iconv" v-model="ext_iconv">{{ t.extensions.iconv }}</v-checkbox>
        <v-checkbox syno-id="cb-intl" v-model="ext_intl">{{ t.extensions.intl }}</v-checkbox>
        <v-checkbox syno-id="cb-calendar" v-model="ext_calendar">{{ t.extensions.calendar }}</v-checkbox>
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

    // Core Extensions
    const ext_opcache = ref(true);
    const ext_tokenizer = ref(true);
    const ext_filter = ref(true);
    const ext_ctype = ref(true);

    // Mathematics
    const ext_bcmath = ref(false);

    // XML & Text Processing
    const ext_xml = ref(true);
    const ext_dom = ref(true);
    const ext_simplexml = ref(true);
    const ext_xmlreader = ref(true);
    const ext_xmlwriter = ref(true);
    const ext_soap = ref(false);

    // Database Extensions
    const ext_pdo = ref(true);
    const ext_mysqli = ref(true);
    const ext_mysqlnd = ref(true);
    const ext_pdo_mysql = ref(true);
    const ext_sqlite3 = ref(true);
    const ext_pdo_sqlite = ref(true);
    const ext_dba = ref(false);

    // Network & Protocols
    const ext_curl = ref(true);
    const ext_openssl = ref(true);
    const ext_ftp = ref(false);
    const ext_sockets = ref(false);

    // Compression & Archives
    const ext_zlib = ref(true);
    const ext_bz2 = ref(false);
    const ext_phar = ref(true);

    // Image Processing
    const ext_gd = ref(true);
    const ext_exif = ref(true);

    // File I/O & Sessions
    const ext_fileinfo = ref(true);
    const ext_session = ref(true);

    // System & Process
    const ext_posix = ref(true);
    const ext_pcntl = ref(false);
    const ext_shmop = ref(false);
    const ext_sysvmsg = ref(false);
    const ext_sysvsem = ref(false);
    const ext_sysvshm = ref(false);

    // Internationalization
    const ext_gettext = ref(false);
    const ext_iconv = ref(true);
    const ext_intl = ref(true);
    const ext_calendar = ref(false);

    // Select/Deselect all functions
    const selectableExtensions = [
      ext_tokenizer, ext_filter, ext_ctype, ext_bcmath, ext_xml, ext_dom, ext_simplexml, ext_xmlreader, ext_xmlwriter, ext_soap, ext_pdo, ext_mysqli, ext_mysqlnd, ext_pdo_mysql, ext_sqlite3, ext_pdo_sqlite, ext_dba, ext_curl, ext_openssl, ext_ftp, ext_sockets, ext_zlib, ext_bz2, ext_phar, ext_gd, ext_exif, ext_fileinfo, ext_session, ext_posix, ext_pcntl, ext_shmop, ext_sysvmsg, ext_sysvsem, ext_sysvshm, ext_gettext, ext_iconv, ext_intl, ext_calendar
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
        pkgwizard_ext_opcache: ext_opcache.value,
        pkgwizard_ext_tokenizer: ext_tokenizer.value,
        pkgwizard_ext_filter: ext_filter.value,
        pkgwizard_ext_ctype: ext_ctype.value,
        pkgwizard_ext_bcmath: ext_bcmath.value,
        pkgwizard_ext_xml: ext_xml.value,
        pkgwizard_ext_dom: ext_dom.value,
        pkgwizard_ext_simplexml: ext_simplexml.value,
        pkgwizard_ext_xmlreader: ext_xmlreader.value,
        pkgwizard_ext_xmlwriter: ext_xmlwriter.value,
        pkgwizard_ext_soap: ext_soap.value,
        pkgwizard_ext_pdo: ext_pdo.value,
        pkgwizard_ext_mysqli: ext_mysqli.value,
        pkgwizard_ext_mysqlnd: ext_mysqlnd.value,
        pkgwizard_ext_pdo_mysql: ext_pdo_mysql.value,
        pkgwizard_ext_sqlite3: ext_sqlite3.value,
        pkgwizard_ext_pdo_sqlite: ext_pdo_sqlite.value,
        pkgwizard_ext_dba: ext_dba.value,
        pkgwizard_ext_curl: ext_curl.value,
        pkgwizard_ext_openssl: ext_openssl.value,
        pkgwizard_ext_ftp: ext_ftp.value,
        pkgwizard_ext_sockets: ext_sockets.value,
        pkgwizard_ext_zlib: ext_zlib.value,
        pkgwizard_ext_bz2: ext_bz2.value,
        pkgwizard_ext_phar: ext_phar.value,
        pkgwizard_ext_gd: ext_gd.value,
        pkgwizard_ext_exif: ext_exif.value,
        pkgwizard_ext_fileinfo: ext_fileinfo.value,
        pkgwizard_ext_session: ext_session.value,
        pkgwizard_ext_posix: ext_posix.value,
        pkgwizard_ext_pcntl: ext_pcntl.value,
        pkgwizard_ext_shmop: ext_shmop.value,
        pkgwizard_ext_sysvmsg: ext_sysvmsg.value,
        pkgwizard_ext_sysvsem: ext_sysvsem.value,
        pkgwizard_ext_sysvshm: ext_sysvshm.value,
        pkgwizard_ext_gettext: ext_gettext.value,
        pkgwizard_ext_iconv: ext_iconv.value,
        pkgwizard_ext_intl: ext_intl.value,
        pkgwizard_ext_calendar: ext_calendar.value,
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
      ext_opcache,
      ext_tokenizer,
      ext_filter,
      ext_ctype,
      ext_bcmath,
      ext_xml,
      ext_dom,
      ext_simplexml,
      ext_xmlreader,
      ext_xmlwriter,
      ext_soap,
      ext_pdo,
      ext_mysqli,
      ext_mysqlnd,
      ext_pdo_mysql,
      ext_sqlite3,
      ext_pdo_sqlite,
      ext_dba,
      ext_curl,
      ext_openssl,
      ext_ftp,
      ext_sockets,
      ext_zlib,
      ext_bz2,
      ext_phar,
      ext_gd,
      ext_exif,
      ext_fileinfo,
      ext_session,
      ext_posix,
      ext_pcntl,
      ext_shmop,
      ext_sysvmsg,
      ext_sysvsem,
      ext_sysvshm,
      ext_gettext,
      ext_iconv,
      ext_intl,
      ext_calendar,
    };
  },
});
</script>
