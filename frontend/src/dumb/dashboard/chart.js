import React from 'react';
import { Line } from 'react-chartjs-2';

// можно попробовать переехать на что-то подобное
// chartjs тяжеловат
// http://bl.ocks.org/simenbrekken/6634070

export default class Chart extends React.Component {
  constructor(props) {
    super(props);

    this.size = 100;

    this.state = {
      ready: false,
      window: new Array(this.size).fill({processed: 0, failed: 0})
    };
  }

  static getDerivedStateFromProps(props, state) {
    if (!state.ready && props.processed === 0 && props.failed === 0) {
      return null;
    }

    const newState = {
      ready: true,
      previous: props
    };

    if (state.previous) {
      const window = state.window.slice();
      window.shift();
      window.push({
        processed: props.processed - state.previous.processed,
        failed:    props.failed    - state.previous.failed
      });
      newState.window = window;
    }

    return newState;
  }

  render() {
    const { window } = this.state;

    const datasetOpts = {
      fill: false,
      pointRadius: 0,
      lineTension: 0
    };

    const data = {
      labels: window.map( (_, i) => i ),

      datasets: [
        {
          ...datasetOpts,
          label: 'Processed',
          borderColor: '#28a745',
          data: window.map( item => item.processed )
        }, {
          ...datasetOpts,
          label: 'Failed',
          borderColor: '#dc3545',
          data: window.map( item => item.failed )
        }
      ]
    };

    const options = {
      scales: {
        xAxes: [{
          display: false
        }],
        yAxes: [{
          ticks: {
            min: 0
          }
        }]
      },
      animation: {
        duration: 0
      }
    };

    return (
      <div className="my-3">
        <Line data={data} options={options} />
      </div>
    );
  }
}
