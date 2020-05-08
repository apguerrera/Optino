Vue.use(Vuex);
Vue.use(VueApexCharts);

Vue.component('apexchart', VueApexCharts);
Vue.component('connection', Connection);
Vue.component('tokenContract', TokenContract);
Vue.component('tokens', Tokens);
Vue.component('payoff', Payoff);
Vue.component('priceFeed', PriceFeed);
Vue.component('optinoFactory', OptinoFactory);
Vue.component('dataService', DataService);
Vue.component('ipfsService', IpfsService);
Vue.component('flat-pickr', VueFlatpickr);

const router = new VueRouter({
  routes,
});

const storeVersion = 1;
const store = new Vuex.Store({
  strict: true,
  // state: {
  //   username: 'Jack',
  //   phrases: ['Welcome back', 'Have a nice day'],
  // },
  // getters: {
  //   getMessage(state) {
  //     return state.route.name === 'top' ?
  //       `${state.phrases[0]}, ${state.username}` :
  //       `${state.phrases[1]}, ${state.username}`;
  //   },
  // },
  mutations: {
    initialiseStore(state) {
      // Check if the store exists
    	if (localStorage.getItem('store')) {
    		let store = JSON.parse(localStorage.getItem('store'));

    		// Check the version stored against current. If different, don't
    		// load the cached version
    		if(store.version == storeVersion) {
          // logDebug("store.initialiseStore BEFORE", JSON.stringify(state, null, 4));
    			this.replaceState(
    				Object.assign(state, store.state)
    			);
          // logDebug("store.initialiseStore AFTER", JSON.stringify(state, null, 4));
    		} else {
    			state.version = storeVersion;
    		}
    	}
    }
  },
  modules: {
    connection: connectionModule,
    tokenContract: tokenContractModule,
    tokens: tokensModule,
    payoff: payoffModule,
    priceFeed: priceFeedModule,
    optinoFactory: optinoFactoryModule,
    dataService: dataServiceModule,
    ipfsService: ipfsServiceModule,
    tokenContractExplorer: tokenContractExplorerModule,
    optinoExplorer: optinoExplorerModule,
    priceFeedExplorer: priceFeedExplorerModule,
    goblokIpfsExplorer: goblokIpfsExplorerModule,
    goblokApi: apiReferenceModule,
    goblokDataServiceExplorer: goblokDataServiceExplorerModule,
  }
});

// Subscribe to store updates
store.subscribe((mutation, state) => {
  let store = {
		version: storeVersion,
		state: state,
	};
  // logDebug("store.updated", JSON.stringify(store, null, 4));
	localStorage.setItem('store', JSON.stringify(store));
});

// sync store and router by using `vuex-router-sync`
sync(store, router);

const app = new Vue({
  router,
  store,
  beforeCreate() {
    setLogLevel(1); // 0 = NONE, 1 = INFO (default), 2 = DEBUG
    logDebug("index.js", "app:beforeCreate()");
		this.$store.commit('initialiseStore');
	}
  // components: {
  //   "network": Network,
  //   "account": Account,
  // }
}).$mount('#app');
