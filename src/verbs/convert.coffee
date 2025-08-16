###*
Implementation of the 'convert' verb for HackMyResume.
@module verbs/convert
@license MIT. See LICENSE.md for details.
###



ResumeFactory = require('../core/resume-factory')
chalk = require('chalk')
Verb = require('../verbs/verb')
HMSTATUS = require('../core/status-codes')
_ = require('underscore')
HMEVENT = require('../core/event-codes');



module.exports = class ConvertVerb extends Verb

  constructor: -> super 'convert', _convert



###* Private workhorse method. Convert 0..N resumes between FRESH and JRS
formats. ###

_convert = ( srcs, dst, opts ) ->

  # If no source resumes are specified, error out
  if !srcs || !srcs.length
    @err HMSTATUS.resumeNotFound, { quit: true }
    return null

  # If no destination resumes are specified, error out except for the special
  # case of two resumes:
  #   hackmyresume CONVERT r1.json r2.json
  if !dst || !dst.length
    if srcs.length == 1
      @err HMSTATUS.inputOutputParity, { quit: true }
    else if srcs.length == 2
      dst = dst || []; dst.push( srcs.pop() )
    else
      @err HMSTATUS.inputOutputParity, { quit: true }

  # Different number of source and dest resumes? Error out.
  if srcs && dst && srcs.length && dst.length && srcs.length != dst.length
    @err HMSTATUS.inputOutputParity, { quit: true }

  # Validate the destination format (if specified)
  targetVer = null
  if opts.format
    fmtUp = opts.format.trim().toUpperCase()
    if not _.contains ['FRESH','FRESCA','JRS','JRS@1','JRS@edge'], fmtUp
      @err HMSTATUS.invalidSchemaVersion, data: opts.format.trim(), quit: true
    # freshVerRegex = require '../utils/fresh-version-regex'
    # matches = fmtUp.match freshVerRegex()
    # # null
    # # [ 'JRS@1.0', 'JRS', '1.0', index: 0, input: 'FRESH' ]
    # # [ 'FRESH', 'FRESH', undefined, index: 0, input: 'FRESH' ]
    # if not matches
    #   @err HMSTATUS.invalidSchemaVersion, data: opts.format.trim(), quit: true
    # targetSchema = matches[1]
    # targetVer = matches[2] || '1'

  # If any errors have occurred this early, we're done.
  if @hasError()
    @reject @errorCode
    return null

  # Map each source resume to the converted destination resume
  results = _.map srcs, ( src, idx ) ->

    # Convert each resume in turn
    r = _convertOne.call @, src, dst, idx, fmtUp

    # Handle conversion errors
    if r.fluenterror
      r.quit = opts.assert
      @err r.fluenterror, r
    r
  , @


  if @hasError() and !opts.assert
    @reject results
  else if !@hasError()
    @resolve results
  results



###* Private workhorse method. Convert a single resume. ###
_convertOne = (src, dst, idx, targetSchema) ->

  # Load the resume
  rinfo = ResumeFactory.loadOne src,
    format: null
    objectify: true
    inner:
      privatize: false

  # If a load error occurs, report it and move on to the next file (if any)
  if rinfo.fluenterror
    @stat HMEVENT.beforeConvert,
      srcFile: src #rinfo.file
      srcFmt: '???'
      dstFile: dst[idx]
      dstFmt: '???'
      error: true
    #@err rinfo.fluenterror, rinfo
    return rinfo

  # Determine the resume's SOURCE format
  # TODO: replace with detector component
  rez = rinfo.rez
  srcFmt = ''
  if rez.meta && rez.meta.format #&& rez.meta.format.substr(0, 5).toUpperCase() == 'FRESH'
    srcFmt = 'FRESH'
  else if rez.basics
    srcFmt = 'JRS'
  else
    rinfo.fluenterror = HMSTATUS.unknownSchema
    return rinfo

  # Determine the TARGET format for the conversion
  targetFormat = targetSchema or (if srcFmt == 'JRS' then 'FRESH' else 'JRS')

  # Fire the beforeConvert event
  this.stat HMEVENT.beforeConvert,
    srcFile: rinfo.file
    srcFmt: srcFmt
    dstFile: dst[idx]
    dstFmt: targetFormat

  # Save it to the destination format
  try
    rez.saveAs dst[idx], targetFormat
  catch err
    if err.badVer
      return fluenterror: HMSTATUS.invalidSchemaVersion, quit: true, data: err.badVer
  rez
