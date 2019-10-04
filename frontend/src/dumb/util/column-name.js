import React from 'react';

export default function ColumnName({name, order, onClick}) {
  const orderSymble = {
    desc: '▼', // по убыванию
    asc: '▲'   // по возрастанию
  };

  let presentedName = name;
  if (orderSymble[order]) {
    presentedName += `&nbsp;${orderSymble[order]}`;
  }

  return (
    <button
      className="btn btn-link font-weight-bold py-0"
      onClick={_ => onClick(name)}
      dangerouslySetInnerHTML={{ __html: presentedName }}
      />
  );
}
