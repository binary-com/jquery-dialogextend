define ["jquery", "jquery-ui"], ($, $ui) ->
  $.widget "ui.dialogExtend",
    version: "2.0.0"
    
    modes:{}
    options:
      "closable" : true
      "dblclick" : false
      "titlebar" : false
      "icons" :
        "close" : "ui-icon-closethick"
        "restore" : "ui-icon-newwin"
      # callbacks
      "load" : null
      "beforeRestore" : null
      "restore" : null
      "resize": null

    _create: ()->
      @_state = "normal"
      if not $(@element[0]).data "ui-dialog"
        $.error "jQuery.dialogExtend Error : Only jQuery UI Dialog element is accepted" 
      @_verifyOptions()
      @_initStyles()
      @_initButtons()
      @_initTitleBar()
      @_setState "normal"
      me = this
      $(window).on 'resize',() ->
        if me.state() == "maximized"
          me.maximize()
          me._trigger "resize"
          return
      @_trigger "load"
    
    _setState: (state)->
      $(@element[0])
      .removeClass("ui-dialog-"+@_state)
      .addClass("ui-dialog-"+state)
      @_state = state
    
    _verifyOptions: ()->
      # check <dblckick> option
      if @options.dblclick and @options.dblclick not of @modes
        $.error "jQuery.dialogExtend Error : Invalid <dblclick> value '" + @options.dblclick + "'"
        @options.dblclick = false
      # check <titlebar> option
      if @options.titlebar and @options.titlebar not in ["none","transparent"]
        $.error "jQuery.dialogExtend Error : Invalid <titlebar> value '" + @options.titlebar + "'"
        @options.titlebar = false;
      # check modules options
      for name of @modes
        if @["_verifyOptions_"+name] then @["_verifyOptions_"+name]()
    
    _initStyles:()->
      if not $(".dialog-extend-css").length
        style = ''
        style += '<style class="dialog-extend-css" type="text/css">'
        style += '.ui-dialog .ui-dialog-titlebar-buttonpane>a { float: right; }'
        style += '.ui-dialog .ui-dialog-titlebar-restore { width: 19px; height: 18px; }'
        style += '.ui-dialog .ui-dialog-titlebar-restore span { display: block; margin: 1px; }'
        style += '.ui-dialog .ui-dialog-titlebar-restore:hover,'
        style += '.ui-dialog .ui-dialog-titlebar-restore:focus { padding: 0; }'
        style += '.ui-dialog .ui-dialog-titlebar ::selection { background-color: transparent; }'
        style += '</style>'
        $(style).appendTo("body")
      for name of @modes
        @["_initStyles_"+name]()

    _initButtons:()->
      # start operation on titlebar
      titlebar = $(@element[0]).dialog("widget").find ".ui-dialog-titlebar"
      # create container for buttons
      buttonPane = $('<div class="ui-dialog-titlebar-buttonpane"></div>').appendTo titlebar
      buttonPane.css
        "position" : "absolute"
        "top" : "50%"
        "right" : "0.3em"
        "margin-top" : "-10px"
        "height" : "18px"
      # move 'close' button to button-pane
      titlebar
        .find(".ui-dialog-titlebar-close")
          # override some unwanted jquery-ui styles
          .css
            "position" : "relative"
            "float" : "right"
            "top" : "auto"
            "right" : "auto"
            "margin" : 0
          # change icon
          .find(".ui-icon").removeClass("ui-icon-closethick").addClass(@options.icons.close).end()
          # move to button-pane
          .appendTo(buttonPane)
        .end()
      # append restore button to button-pane
      buttonPane
        .append('<a class="ui-dialog-titlebar-restore ui-corner-all ui-state-default" href="#"><span class="ui-icon '+@options.icons.restore+'" title="restore">restore</span></a>')
        # add effect to button
        .find('.ui-dialog-titlebar-restore')
          .attr("role", "button")
          .mouseover(()-> $(@).addClass("ui-state-hover"))
          .mouseout(()-> $(@).removeClass("ui-state-hover"))
          .focus(()-> $(@).addClass("ui-state-focus"))
          .blur(()-> $(@).removeClass("ui-state-focus"))
        .end()
        # default show buttons
        # set button positions
        # on-click-button
        .find(".ui-dialog-titlebar-close")
          .toggle(@options.closable)
        .end()
        .find(".ui-dialog-titlebar-restore")
          .hide()
          .click((e)=>
            e.preventDefault()
            @restore()
          )
        .end();
        # add buttons from modules
        for name,mode of @modes
          @_initModuleButton name,mode

      # other titlebar behaviors
      titlebar
        # on-dblclick-titlebar
        .dblclick((evt)=>
          if @options.dblclick
            if @_state != "normal"
              @restore()
            else
              @[@options.dblclick]()
        )
        # avoid text-highlight when double-click
        .select(()->
          return false
        )
    
    _initModuleButton:(name,mode)->
      buttonPane = $(@element[0]).dialog("widget").find '.ui-dialog-titlebar-buttonpane'
      buttonPane.append('<a class="ui-dialog-titlebar-'+name+' ui-corner-all ui-state-default" href="#" title="'+name+'"><span class="ui-icon '+@options.icons[name]+'">'+name+'</span></a>')
        .find(".ui-dialog-titlebar-"+name)
          .attr("role", "button")
          .mouseover(()-> $(@).addClass("ui-state-hover"))
          .mouseout(()-> $(@).removeClass("ui-state-hover"))
          .focus(()-> $(@).addClass("ui-state-focus"))
          .blur(()-> $(@).removeClass("ui-state-focus"))
        .end()
        .find(".ui-dialog-titlebar-"+name)
          .toggle(@options[mode.option])
          .click((e)=>
            e.preventDefault()
            @[name]()
          )
          .end()

    _initTitleBar:()->
      switch @options.titlebar
          when false then 0
          when "none"
            # create new draggable-handle as substitute of title bar
            if $(@element[0]).dialog("option", "draggable")
              handle = $("<div />").addClass("ui-dialog-draggable-handle").css("cursor", "move").height(5)
              $(@element[0]).dialog("widget").prepend(handle).draggable("option", "handle", handle);
            # remove title bar and keep it draggable
            $(@element[0])
              .dialog("widget")
              .find(".ui-dialog-titlebar")
                # clear title text
                .find(".ui-dialog-title").html("&nbsp;").end()
                # keep buttons at upper-right-hand corner
                .css(
                  "background-color" : "transparent"
                  "background-image" : "none"
                  "border" : 0
                  "position" : "absolute"
                  "right" : 0
                  "top" : 0
                  "z-index" : 9999
                )
              .end();
          when "transparent"
            # remove title style
            $(@element[0])
              .dialog("widget")
              .find(".ui-dialog-titlebar")
              .css(
                "background-color" : "transparent"
                "background-image" : "none"
                "border" : 0
              )
          else
            $.error( "jQuery.dialogExtend Error : Invalid <titlebar> value '" + @options.titlebar + "'" );

    state:()->
      return @_state

    restore:()->
      # trigger custom event
      @_trigger "beforeRestore"
      @_restore()
      # modify dialog buttons according to new state
      @_toggleButtons()
      # trigger custom event
      @_trigger "restore"
    
    _restore:()->
      unless @_state is "normal"
        @["_restore_"+@_state]()
        # mark new state
        @_setState "normal"
        $(this.element[0]).dialog("widget").addClass('ui-corner-all')
        # return focus to window
        $(@element[0]).dialog("widget").focus()
    
    _saveSnapshot:()->
      if @_state is "normal" 
        @original_config_resizable = $(@element[0]).dialog("option", "resizable")
        @original_config_draggable = $(@element[0]).dialog("option", "draggable")
        @original_size_height = $(@element[0]).dialog("widget").outerHeight()
        @original_size_width = $(@element[0]).dialog("option", "width")
        @original_size_maxHeight = $(@element[0]).dialog("option", "maxHeight")
        @original_position_mode = $(@element[0]).dialog("widget").css("position")
        @original_position_left = $(@element[0]).dialog("widget").offset().left-$('body').scrollLeft()
        @original_position_top = $(@element[0]).dialog("widget").offset().top-$('body').scrollTop()
        @original_titlebar_wrap = $(@element[0]).dialog("widget").find(".ui-dialog-titlebar").css("white-space")

    _loadSnapshot:()->
      {
        "config" :
          "resizable" : @original_config_resizable
          "draggable" : @original_config_draggable
        "size" :
          "height" : @original_size_height
          "width"  : @original_size_width
          "maxHeight" : @original_size_maxHeight
        "position" :
          "mode" : @original_position_mode
          "left" : @original_position_left
          "top"  : @original_position_top
        "titlebar" :
          "wrap" : @original_titlebar_wrap
      }
    
    _toggleButtons:(newstate)->
      state = newstate or @_state
      $(@element[0]).dialog("widget")
        .find(".ui-dialog-titlebar-restore")
          .toggle( state != "normal" )
          .css({ "right" : "1.4em" })
        .end()
      for name,mode of @modes
        $(@element[0]).dialog("widget")
        .find(".ui-dialog-titlebar-"+name)
        .toggle( state != mode.state && @options[mode.option] )
      # place restore button after current state button
      for name,mode of @modes
        if mode.state is state
          $(@element[0]).dialog("widget")
            .find(".ui-dialog-titlebar-restore")
              .insertAfter(
                $(@element[0]).dialog("widget")
                .find(".ui-dialog-titlebar-"+name)
              ).end()

  $.extend true,$.ui.dialogExtend.prototype,
    modes:
      "collapse":
        option:"collapsable"
        state:"collapsed"
    options:
      "collapsable" : true
      "icons" :
        "collapse": "ui-icon-triangle-1-s"
      # callbacks
      "beforeCollapse" : null
      "collapse" : null

    collapse:()->
      newHeight = $(@element[0]).dialog("widget").find(".ui-dialog-titlebar").height()+15;
      # start!
      # trigger custom event
      @_trigger "beforeCollapse"
      # restore to normal state first (when necessary)
      unless @_state is "normal"
        @_restore()
      # remember original state
      @_saveSnapshot()
      pos = $(@element[0]).dialog("widget").position()
      $(@element[0])
        # modify dialog size (after hiding content)
        .dialog("option",
          "resizable" : false
          "height" : newHeight
          "maxHeight" : newHeight
          "position" : [pos.left - $(document).scrollLeft(),pos.top - $(document).scrollTop()]
        )
        .on('dialogclose',@_collapse_restore)
        # hide content
        # hide button-pane
        # make title-bar no-wrap
        .hide()
        .dialog("widget")
          .find(".ui-dialog-buttonpane:visible").hide().end()
          .find(".ui-dialog-titlebar").css("white-space", "nowrap").end()
        .find(".ui-dialog-content")
        # mark new state
        @_setState "collapsed"
        # modify dialog buttons according to new state
        @_toggleButtons()
        # trigger custom event
        @_trigger "collapse"

    _restore_collapsed:()->
      original = @_loadSnapshot()
      # restore dialog
      $(@element[0])
        # show content
        # show button-pane
        # fix title-bar wrap
        .show()
        .dialog("widget")
          .find(".ui-dialog-buttonpane:hidden").show().end()
          .find(".ui-dialog-titlebar").css("white-space", original.titlebar.wrap).end()
        .find(".ui-dialog-content")
        # restore config & size
        .dialog("option",
          "resizable" : original.config.resizable
          "height" : original.size.height
          "maxHeight" : original.size.maxHeight
        )
        .off('dialogclose',@_collapse_restore)

    _initStyles_collapse:()->
      if not $(".dialog-extend-collapse-css").length
        style = ''
        style += '<style class="dialog-extend-collapse-css" type="text/css">'
        style += '.ui-dialog .ui-dialog-titlebar-collapse { width: 19px; height: 18px; }'
        style += '.ui-dialog .ui-dialog-titlebar-collapse span { display: block; margin: 1px; }'
        style += '.ui-dialog .ui-dialog-titlebar-collapse:hover,'
        style += '.ui-dialog .ui-dialog-titlebar-collapse:focus { padding: 0; }'
        style += '</style>'
        $(style).appendTo("body")
    
    _collapse_restore:()->
      $(@).dialogExtend("restore")

  $.extend true,$.ui.dialogExtend.prototype,
    modes:
      "maximize":
        option:"maximizable"
        state:"maximized"
    options:
      "maximizable" : true
      "icons" :
        "maximize" : "ui-icon-extlink"
      # callbacks
      "beforeMaximize" : null
      "maximize" : null

    maximize:()->
      newHeight = $(window).height();
      newWidth = $(window).width()-11;
      # start!
      # trigger custom event
      @_trigger "beforeMaximize"
      # restore to normal state first (when necessary)
      unless @_state is "normal"
        @_restore()
      # remember original state
      @_saveSnapshot()
      # disable draggable-handle (for <titlebar=none> only)
      if $(@element[0]).dialog("option","draggable")
        $(@element[0])
        .dialog("widget")
          .draggable("option", "handle", null)
          .find(".ui-dialog-draggable-handle").css("cursor", "text").end()
      $(@element[0])
        # fix dialog from scrolling
        .dialog("widget")
          .css("position", "fixed")
        .find(".ui-dialog-content")
        # show content
        # show button-pane (when minimized/collapsed)
        .show()
        .dialog("widget")
          .find(".ui-dialog-buttonpane").show().end()
        .find(".ui-dialog-content")
        # modify dialog with new config
        .dialog("option",
          "resizable" : false
          "draggable" : false
          "height" : newHeight
          "width" : newWidth
          "position" :
              my: "left top"
              at: "left top"
              of: window
        )
        
        $(this.element[0]).dialog("widget").removeClass('ui-corner-all');
        # mark new state
        @_setState "maximized"
        # modify dialog buttons according to new state
        @_toggleButtons()
        # trigger custom event
        @_trigger "maximize"
    _restore_maximized:()->
      original = @_loadSnapshot()
      # restore dialog
      $(@element[0])
        # free dialog from scrolling
        # fix title-bar wrap (if dialog was minimized/collapsed)
        .dialog("widget")
          .css("position", original.position.mode)
          .find(".ui-dialog-titlebar").css("white-space", original.titlebar.wrap).end()
        .find(".ui-dialog-content")
        # restore config & size
        .dialog("option",
          "resizable" : original.config.resizable
          "draggable" : original.config.draggable
          "height" : original.size.height
          "width" : original.size.width
          "maxHeight" : original.size.maxHeight
          "position" :
            my: "left top"
            at: "left+"+original.position.left+" top+"+original.position.top
            of: window
        )
        # restore draggable-handle (for <titlebar=none> only)
        if $(@element[0]).dialog("option","draggable")
          $(@element[0])
          .dialog("widget")
            .draggable("option", "handle", if $(@element[0]).dialog("widget").find(".ui-dialog-draggable-handle").length then $(@element[0]).dialog("widget").find(".ui-dialog-draggable-handle") else".ui-dialog-titlebar")
            .find(".ui-dialog-draggable-handle")
            .css("cursor", "move");

    _initStyles_maximize:()->
      if not $(".dialog-extend-maximize-css").length
        style = ''
        style += '<style class="dialog-extend-maximize-css" type="text/css">'
        style += '.ui-dialog .ui-dialog-titlebar-maximize { width: 19px; height: 18px; }'
        style += '.ui-dialog .ui-dialog-titlebar-maximize span { display: block; margin: 1px; }'
        style += '.ui-dialog .ui-dialog-titlebar-maximize:hover,'
        style += '.ui-dialog .ui-dialog-titlebar-maximize:focus { padding: 0; }'
        style += '</style>'
        $(style).appendTo("body")

  $.extend true,$.ui.dialogExtend.prototype,
    modes:
      "minimize":
        option:"minimizable"
        state:"minimized"
    options:
      "minimizable" : true
      "minimizeLocation" : "left"
      "icons" :
        "minimize" : "ui-icon-minus"
      # callback
      "beforeMinimize" : null
      "minimize" : null
    
    minimize:()->
      # trigger custom event
      @_trigger "beforeMinimize"
      unless @_state is "normal"
        @_restore()
      # caculate new dimension
      newWidth = 200
      # create container for (multiple) minimized dialogs (when necessary)
      if $("#dialog-extend-fixed-container").length
        fixedContainer = $("#dialog-extend-fixed-container")
      else
        fixedContainer = $('<div id="dialog-extend-fixed-container"></div>').appendTo("body")
        fixedContainer.css
          "position" : "fixed"
          "bottom" : 1
          "left" : 1
          "right" : 1
          "z-index" : 9999
      # prepare dialog buttons for new state
      @_toggleButtons("minimized")
      dialogcontrols = $(@element[0]).dialog("widget").clone().children().remove().end()
      $(@element[0]).dialog("widget").find('.ui-dialog-titlebar').clone(true,true).appendTo(dialogcontrols)
      dialogcontrols.css
        # float is essential for stacking dialog when there are many many minimized dialogs
        "float" : @options.minimizeLocation,
        "margin" : 1
      fixedContainer.append(dialogcontrols)
      $(@element[0]).data("dialog-extend-minimize-controls",dialogcontrols)
      # disable draggable-handle (for <titlebar=none> only)
      if $(@element[0]).dialog("option","draggable")
        dialogcontrols.removeClass("ui-draggable")
      # modify dialogcontrols
      dialogcontrols.css
        "height": "auto"
        "width": newWidth
        "position": "static"
      # restore dialog before close
      $(@element[0]).on('dialogbeforeclose',@_minimize_restoreOnClose)
      # hide original dialog
      .dialog("widget").hide()
      # mark new state
      @_setState "minimized"
      # trigger custom event
      @_trigger "minimize"

    _restore_minimized:()->
      # restore dialog
      $(@element[0]).dialog("widget").show()
      # disable close handler
      $(@element[0]).off('dialogbeforeclose',@_minimize_restoreOnClose)
      # remove dialogcontrols
      $(@element[0]).data("dialog-extend-minimize-controls").remove()
      $(@element[0]).removeData("dialog-extend-minimize-controls")

    _initStyles_minimize:()->
      if not $(".dialog-extend-minimize-css").length
        style = ''
        style += '<style class="dialog-extend-minimize-css" type="text/css">'
        style += '.ui-dialog .ui-dialog-titlebar-minimize { width: 19px; height: 18px; }'
        style += '.ui-dialog .ui-dialog-titlebar-minimize span { display: block; margin: 1px; }'
        style += '.ui-dialog .ui-dialog-titlebar-minimize:hover,'
        style += '.ui-dialog .ui-dialog-titlebar-minimize:focus { padding: 0; }'
        style += '</style>'
        $(style).appendTo("body")
    
    _verifyOptions_minimize:()->
      if not @options.minimizeLocation or @options.minimizeLocation not in ['left','right']
        $.error( "jQuery.dialogExtend Error : Invalid <minimizeLocation> value '" + @options.minimizeLocation + "'" )
        @options.minimizeLocation = "left"
    
    _minimize_restoreOnClose:()->
      $(@).dialogExtend("restore")
  return