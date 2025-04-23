###*
Definition of the AbstractResume class.
@license MIT. See LICENSE.md for details.
@module core/abstract-resume
###

_ = require 'underscore'
__ = require 'lodash'
FluentDate = require('./fluent-date')

class AbstractResume

  ###*
  Compute the total duration of the work history.
  @returns The total duration of the sheet's work history, that is, the number
  of years between the start date of the earliest job on the resume and the
  *latest end date of all jobs in the work history*. This last condition is for
  sheets that have overlapping jobs.
  ###
  duration: (collKey, startKey, endKey, unit) ->
    unit = unit || 'years'
    hist = __.get @, collKey
    return 0 if !hist or !hist.length

    # BEGIN CODE DUPLICATION --> src/inspectors/gap-inspector.coffee (TODO)

    # Convert the candidate's employment history to an array of dates,
    # where each element in the array is a start date or an end date of a
    # job -- it doesn't matter which.
    new_e = hist.map ( job ) ->
      obj = _.pick( job, [startKey, endKey] )
      # Synthesize an end date if this is a "current" gig
      obj[endKey] = 'current' if !_.has obj, endKey
      if obj && (obj[startKey] || obj[endKey])
        obj = _.pairs obj
        obj[0][1] = FluentDate.fmt( obj[0][1] )
        if obj.length > 1
          obj[1][1] = FluentDate.fmt( obj[1][1] )
      obj

    # Flatten the array, remove empties, and sort
    new_e = _.filter _.flatten( new_e, true ), (v) ->
      return v && v.length && v[0] && v[0].length
    return 0 if !new_e or !new_e.length
    new_e = _.sortBy new_e, ( elem ) -> return elem[1].unix()

    # END CODE DUPLICATION

    firstDate = _.first( new_e )[1];
    lastDate = _.last( new_e )[1];
    lastDate.diff firstDate, unit

  ###*
  Removes ignored or private fields from a resume object
  @returns an object with the following structure:
  {
    scrubbed: the processed resume object
    ignoreList: an array of ignored nodes that were removed
    privateList: an array of private nodes that were removed
  }
  ###
  scrubResume: (rep, opts) ->
    traverse = require 'traverse'
    ignoreList = []
    privateList = []
    includePrivates = opts && opts.private

    scrubbed = traverse( rep ).map () -> # [^1]
      if !@isLeaf
        if @node.ignore == true || @node.ignore == 'true'
          ignoreList.push @node
          @delete()
        else if (@node.private == true || @node.private == 'true') && !includePrivates
          privateList.push @node
          @delete()
      if _.isArray(@node) # [^2]
        @after () ->
          @update _.compact this.node
          return
      return

    scrubbed: scrubbed
    ingoreList: ignoreList
    privateList: privateList

module.exports = AbstractResume


# [^1]: As of v0.6.6, the NPM traverse library has a quirk when attempting
# to remove array elements directly using traverse's `this.remove`. See:
#
# https://github.com/substack/js-traverse/issues/48
#
# [^2]: The workaround is to use traverse's 'this.delete' to nullify the value
# first, followed by removal with something like _.compact.
#
# https://github.com/substack/js-traverse/issues/48#issuecomment-142607200
#
