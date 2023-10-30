/**
Implementation of the 'analyze' verb for HackMyResume.
@module create.js
@license MIT. See LICENSE.md for details.
*/



(function(){



  var MKDIRP = require('mkdirp')
    , PATH = require('path')
    , HME = require('../core/event-codes')
    , _ = require('underscore')
    , ResumeFactory = require('../core/resume-factory')
    , Verb = require('../verbs/verb')
    , chalk = require('chalk');



  var AnalyzeVerb = module.exports = Verb.extend({

    init: function() {
      this._super('analyze');
    },

    invoke: function() {
      analyze.apply( this, arguments );
    }

  });



  /**
  Run the 'analyze' command.
  */
  function analyze( sources, dst, opts ) {
    this.stat('begin');
    if( !sources || !sources.length ) throw { fluenterror: 3 };
    var nlzrs = _loadInspectors();
    _.each(sources, function(src) {
      var result = ResumeFactory.loadOne( src, {
        format: 'FRESH', objectify: true, throw: false
      });
      result.error || _analyze.call(this, result, nlzrs, opts );
    }, this);
    this.stat('end');
  }



  /**
  Analyze a single resume.
  */
  function _analyze( resumeObject, nlzrs, opts ) {
    var rez = resumeObject.rez;
    var safeFormat =
      (rez.meta && rez.meta.format && rez.meta.format.startsWith('FRESH')) ?
      'FRESH' : 'JRS';

    this.stat( HME.beforeAnalyze, { fmt: safeFormat, file: resumeObject.file });
    var info = _.mapObject( nlzrs, function(val, key) {
      return val.run( resumeObject.rez );
    });
    this.stat( HME.afterAnalyze, { info: info } );
  }



  /**
  Load inspectors.
  */
  function _loadInspectors() {
    return {
      totals: require('../inspectors/totals-inspector'),
      coverage: require('../inspectors/gap-inspector'),
      keywords: require('../inspectors/keyword-inspector')
    };
  }



}());
