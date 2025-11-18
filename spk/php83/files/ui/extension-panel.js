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

    me.items = [{
      xtype: 'grid',
      store: me.store,
      columns: [
        { text: 'Name', dataIndex: 'name', flex: 1 },
        { text: 'Category', dataIndex: 'category', width: 120 },
        { text: 'Restart', dataIndex: 'restartRequirement', width: 100 },
        { text: 'Enabled', dataIndex: 'selected', xtype: 'checkcolumn', width: 90 }
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
      success: function () { Ext.Msg.alert('Success', 'Extensions updated.'); },
      failure: function (_, resp) { Ext.Msg.alert('Error', resp.responseText || 'Failed.'); }
    });
  }
});
