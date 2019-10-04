import React from 'react';
import { Link } from "react-router-dom";

import { RoutesContext } from '../routes';

export default function Breadcrumbs({name, page}) {
  return (
    <RoutesContext.Consumer>
      {
        routes => {
          return (
            <nav className="my-3" aria-label="breadcrumb">
              <ol className="breadcrumb">
                <li className="breadcrumb-item">
                  <Link to={routes.dashboard()}>Dashboard</Link>
                </li>
                <li className="breadcrumb-item">{name}</li>
                <li className="breadcrumb-item active">{page}</li>
              </ol>
            </nav>
          );
        }
    }
    </RoutesContext.Consumer>
  );
}
