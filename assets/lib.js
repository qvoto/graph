var chartBuilder = {
  resultData: null,
  topResult:  null,
  numberOfTicks: 9,
  ticks:    [],

  create: function() {
    builder = chartBuilder;
    builder.resultData = resultData;
    builder.show();

    $(window).resize(function() {
      builder.drawChart();
    });
    $(function() {
      builder.showLegend();
    })
  },
  show: function() {
    this.topResult = this._getTopResult();
    this.ticks     = this._getAxisTicks();

    this.drawChart();
  },
  showLegend: function() {
    var colour = function(data) {
      var style =  'style="background-color: ' + data['colour'] + '"';
      return '<div class="colour"><span ' + style + '></span></div>';
    }

    var name   = function(key) {
      return '<div class="name">' + key + '</div>';
    }

    var cleardiv = function() {
      return '<div class="clear"></div>';
    }

    var partyDiv = function(key, data) {
      return '<div class="party">' + colour(data) + name(key) + cleardiv() + '</div>';
    }

    jQuery.each(this.resultData, function(key, data) {
      $('#parties').append(partyDiv(key, data));
    })
  },
  drawChart: function() {
      var element   = document.getElementById('chart');
      var data      = new google.visualization.DataTable();
      var chart     = new google.visualization.BarChart(element);
      var separator = ['', 0, '', ''];

      data.addColumn('string', 'Countries');
      data.addColumn('number', 'Affinity');
      data.addColumn({ type: 'string', role: 'style' });
      data.addColumn({ type: 'string', role: 'annotation' });


      data.addRow(separator);
      jQuery.each(this.resultData, function(key, value) {
        var affinity   = value['affinity'];
        var color      = 'color: ' + value['colour'] + ';'
        var annotation = affinity + '%';
        var row        = [ key, affinity, color, annotation ];

        data.addRow(row);
      })
      data.addRow(separator);

      var options = {
        title          : 'Grado de acuerdo',
        titleTextStyle : { fontSize: '22' },
        width          : '100%',
        height         : '100%',
        legend         : { position: 'none' },
        chartArea      : { width: '90%', height: '80%'},
        bar            : { groupWidth: '100%' },
        vAxis          : { textStyle: { color: 'white', fontSize: 0.1 } },
        hAxis          : { ticks: this.ticks }
      };
      chart.draw(data, options);
   },
  _getTopResult: function(){
    var top = 0;
    $.each(this.resultData, function(key, data) {
      if(data['affinity'] > top) {
        top = data['affinity'];
      }
    });
    return top;
  },
  _getAxisTicks: function() {
    var ticks     = [];
    var number    = 0;
    while(this.topResult >= (number - 10)) {
      var string = number + '%';
      ticks.push({ v: number, f: string });
      number += 10;
    }
    return ticks;
  }
};
