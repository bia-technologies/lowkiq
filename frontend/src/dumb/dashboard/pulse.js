import React from 'react';
import classNames from 'classnames';
import style from './pulse.module.css';

/*
 * на каждое второе получение props срабатывает анимация
 */

export default class Pulse extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      pulse: true
    };
  }

  static getDerivedStateFromProps(props, {pulse}) {
    return { pulse: !pulse };
  }

  render() {
    const classes = classNames(
      'bg-dark', 'rounded-circle',
      style.container,
      {
        [style.pulse]: this.state.pulse
      }
    );
    return (
      <div className={classes} />
    );
  }
};
