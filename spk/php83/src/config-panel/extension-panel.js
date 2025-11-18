Ext.define('PHP83.ExtensionPanel', {
  extend: 'Ext.panel.Panel',
  alias: 'widget.php83extensionpanel',

  title: 'PHP 8.3 Extensions',
  layout: 'fit',

  initComponent: function () {
    var me = this;
    me.store = Ext.create('Ext.data.Store', {
      autoLoad: true,
      fields: ['id', 'name', 'description', 'category', 'defaultEnabled', 'dependencies', 'conflicts', 'restartRequirement', 'selected'],
      proxy: {
        type: 'ajax',
        url: '/webapi/php83/extensions/options',
        reader: { type: 'json' }
      }
    });
    me.store.on('load', function () {
      Ext.Ajax.request({
        url: '/webapi/php83/extensions/profile',
        success: function (resp) {
          var profile = Ext.decode(resp.responseText || '{}');
          me.store.each(function (record) {
            record.set('selected', (profile.selected || []).indexOf(record.get('id')) !== -1);
          });
        }
      });
    });

    me.items = [{
      xtype: 'grid',
      store: me.store,
      columns: [
        { text: 'Name', dataIndex: 'name', flex: 1 },
        { text: 'Category', dataIndex: 'category', width: 120 },
        { text: 'Restart', dataIndex: 'restartRequirement', width: 100 },
        { text: 'Enabled', dataIndex: 'selected', xtype: 'checkcolumn', width: 90 },
        { text: 'Conflicts', renderer: function (_, __, record) { return (record.get('conflicts') || []).join(', '); } }
      ],
      tbar: [{
        text: 'Apply',
        handler: function () { me.applyChanges(); }
      }, {
        text: 'Refresh',
        handler: function () { me.store.reload(); }
      }]
    }];

    me.callParent(arguments);
  },

  applyChanges: function () {
    var payload = { operations: [] };
    this.store.each(function (record) {
      payload.operations.push({ id: record.get('id'), targetState: record.get('selected') ? 'enable' : 'disable' });
    });
    Ext.Ajax.request({
      url: '/webapi/php83/extensions/apply',
      method: 'PATCH',
      jsonData: payload,
      success: function () {
        Ext.Msg.alert('Success', 'Extensions updated.');
        Ext.Ajax.request({
          url: '/webapi/php83/extensions/profile',
          success: function (resp) {
            var profile = Ext.decode(resp.responseText || '{}');
            if (profile.warnings && profile.warnings.length) {
              var msg = profile.warnings.map(function (w) { return w.message; }).join('<br>');
              Ext.Msg.alert('Warnings', msg);
            }
          }
        });
      },
      failure: function (_, resp) { Ext.Msg.alert('Error', resp.responseText || 'Failed.'); }
    });
  }
});
