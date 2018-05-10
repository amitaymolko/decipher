import React from 'react';
import ReactDOM from 'react-dom';
import { Router, Route, IndexRoute, browserHistory } from 'react-router'
import { Provider } from 'react-redux'
import { syncHistoryWithStore } from 'react-router-redux'
import { DrizzleProvider } from 'drizzle-react'
import Portis from 'portis'

__DEV__ = process.env.NODE_ENV !== 'production'

// Layouts
import App from './App'
import HomeContainer from './layouts/home/HomeContainer'
import LoadingContainer from './layouts/loading/LoadingContainer'


import DecipherProd from '../build_production/contracts/Decipher.json'
import DecipherDev from '../build/contracts/Decipher.json'

const Decipher = __DEV__ ? DecipherDev : DecipherProd


// Redux Store
import store from './store'

// Initialize react-router-redux.
const history = syncHistoryWithStore(browserHistory, store)

// const devWebsocketUrl = 'ws://127.0.0.1:7545'
const devWebsocketUrl = 'wss://mainnet.infura.io/ws'

const prodWebsocketUrl = 'wss://mainnet.infura.io/ws'
// const prodWebsocketUrl = 'ws://34.235.133.122:8546'


const WebSocketUrl = __DEV__ ? devWebsocketUrl : prodWebsocketUrl

// Set Drizzle options.
const options = {
  web3: {
    block: false,
    fallback: {
      type: 'ws',
      url: WebSocketUrl
    }
  },
  contracts: [
    Decipher,
  ],
  events: {
    Decipher: ['InvestmentEvent', 'PredictionEvent', 'FailedDecipherEvent', 'DecipherEvent'],
  }
}

ReactDOM.render((
    <DrizzleProvider options={options}>
      <Provider store={store}>
        <LoadingContainer>
          <Router history={history}>
            <Route path="/" component={App}>
              <IndexRoute component={HomeContainer} />
            </Route>
          </Router>
        </LoadingContainer>
      </Provider>
    </DrizzleProvider>
  ),
  document.getElementById('root')
);