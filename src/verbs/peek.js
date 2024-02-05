/**
Implementation of the 'peek' verb for HackMyResume.
@module peek.js
@license MIT. See LICENSE.md for details.
*/



(function(){



  var Verb = require('../verbs/verb')
    , _ = require('underscore')
    , __ = require('lodash')
    , safeLoadJSON = require('../utils/safe-json-loader')
    , HMSTATUS = require('../core/status-codes')
    , HMEVENT = require('../core/event-codes');



  var PeekVerb = module.exports = Verb.extend({

    init: function() {
      this._super('peek');
    },

    invoke: function() {
      peek.apply( this, arguments );
    }

  });



  /**
  Peek at a resume, resume section, or resume field.
  */
  function peek( src, dst, opts ) {

    if(!src || !src.length) throw {fluenterror: HMSTATUS.resumeNotFound};
    this.stat( HMEVENT.begin );

    var objPath = (dst && dst[0]) || '';

    _.each( src, function( t ) {
      this.stat( HMEVENT.beforePeek, { file: t, target: objPath } );

      var obj = safeLoadJSON( t );
      if( obj.ex ) {
        this.err( obj.ex.fluenterror, obj.ex );
      }
      var targ = objPath ? __.get( obj.json, objPath ) : obj.json;

      this.stat( HMEVENT.afterPeek, { file: t, requested: objPath, target: targ } );
    }, this);

    this.stat( HMEVENT.end );
  }



}());
