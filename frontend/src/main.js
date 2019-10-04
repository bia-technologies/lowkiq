import React from 'react';
import ReactDOM from 'react-dom';

import factory from './web-api';

const {lowkiqRoot} = window;
const App = factory(`${lowkiqRoot}/api/web`, lowkiqRoot);

const root = document.getElementById('root');

ReactDOM.render( <App />, root );
