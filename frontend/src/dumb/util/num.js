import React from 'react';

function formatToUnits(number) {
  if (number < 1000) return number;

  const abbrev = ['', 'K', 'M', 'B', 'T'];
  const unrangifiedOrder = Math.floor(Math.log10(Math.abs(number)) / 3);
  const order = Math.max(0, Math.min(unrangifiedOrder, abbrev.length - 1));
  const suffix = abbrev[order];

  return (number / Math.pow(10, order * 3)).toPrecision(3) + suffix;
}

export default function Num({val}) {
  return <span>{formatToUnits(val)}</span>;
}
