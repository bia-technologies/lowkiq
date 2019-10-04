import React from 'react';

function Interval({min, max, rev}) {
  if (!rev && min === '-inf' && max === '+inf') {
    return "(-∞, +∞)";
  } else if (rev && max === '+inf' && min === '-inf') {
    return "(+∞, -∞)";
  } else if (!rev && max === '+inf') {
    return `[val, +∞)`;
  } else if (rev && min === '-inf') {
    return `[val, -∞)`;
  } else {
    throw "invalid interval";
  }
}

function Button({interval, selected, disabled, onClick}) {
  let btnType = selected
      && interval.rev === selected.rev
      && interval.min === selected.min
      && interval.max === selected.max
      ? 'btn-secondary' : 'btn-outline-secondary';
  const handleClick = () => onClick(interval);

  return (
    <button className={`btn ${btnType} text-nowrap`} disabled={disabled} onClick={handleClick}>
      <Interval {...interval} />
    </button>
  );
}

function getVal(selected) {
  if (!selected) return "";

  const {min, max, rev} = selected;
  if (min !== '-inf' && max === '+inf' && rev === false)
    return min;
  if (min === '-inf' && max !== '+inf' && rev === true)
    return max;
  return "";
}

export default class Filter extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      value: getVal(props.selected)
    };
    this.handleChange = this.handleChange.bind(this);
  }

  handleChange(e) {
    this.setState({value: e.target.value});
  }

  render() {
    const {label, selected, type, onClick} = this.props;
    const {value} = this.state;

    return (
      <div className="form-group">

        <label>{label}</label>

        <div className="d-flex">
          <div className="mr-2">
            <Button interval={{min: "-inf", max: "+inf", rev: false}}
                    selected={selected}
                    onClick={onClick} />
          </div>
          <div className="mr-2">
            <Button interval={{max: "+inf", min: "-inf", rev: true}}
                    selected={selected}
                    onClick={onClick} />
          </div>
          <div className="input-group">
            <input type={type}
                   className="form-control"
                   placeholder="val"
                   value={value}
                   onChange={this.handleChange} />

            <div className="input-group-append">
              <Button interval={{min: value, max: "+inf", rev: false}}
                      selected={selected}
                      disabled={value === ''}
                      onClick={onClick} />
              <Button interval={{max: value, min: "-inf", rev: true}}
                      selected={selected}
                      disabled={value === ''}
                      onClick={onClick} />
            </div>
          </div>
        </div>
      </div>
    );
  }
}
