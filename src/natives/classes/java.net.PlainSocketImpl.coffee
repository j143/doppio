native_methods.java.net.PlainSocketImpl = [
  o 'socketCreate(Z)V', (rs, _this, isServer) ->
    # Check to make sure we're in a browser and the websocket libraries are present
    rs.java_throw rs.get_bs_class('Ljava/io/IOException;'), 'WebSockets are disabled' unless node?
    
    fd = _this.get_field rs, 'Ljava/net/SocketImpl;fd'
    
    # Make the FileDescriptor valid with a dummy fd
    fd.set_field rs, 'Ljava/io/FileDescriptor;fd', 8374
    
    # Finally, create our websocket instance
    _this.$ws = new Websock()

  o 'socketConnect(Ljava/net/InetAddress;II)V', (rs, _this, address, port, timeout) ->
    # The IPv4 case
    holder = address.get_field rs, 'Ljava/net/InetAddress;holder'
    addy = holder.get_field rs, 'Ljava/net/InetAddress$InetAddressHolder;address'
    # Assume scheme is ws for now
    host = 'ws://'
    if host_lookup[addy] is undefined
      # Populate host string based off of IP address
      for i in [3 .. 0] by -1
        shift = i * 8
        host += "#{(addy & (0xFF << shift)) >> shift}."
    else
      host += host_lookup[addy]
    # trim last '.'
    host = host.substring 0, host.length - 1
    # Add port
    host += ":#{port}"
    
    debug "Connecting to #{host} with timeout = #{timeout} ms"
    
    
    rs.async_op (resume_cb, except_cb) ->
      id = 0
      
      clear_state = ->
        window.clearTimeout id
        _this.$ws.on('open', ->)
        _this.$ws.on('close', ->)
        _this.$ws.on('error', ->)
      
      error_cb = (msg) -> ->
        clear_state()
        except_cb -> rs.java_throw rs.get_bs_class('Ljava/io/IOException;'), msg
      
      # Success case
      _this.$ws.on('open', ->
        debug 'Open!'
        clear_state()
        resume_cb())
      
      # Error cases
      _this.$ws.on('close', error_cb('Connection failed! (Closed)'))
      _this.$ws.on('error', error_cb('Connection failed! (Error)'))
      
      # Timeout case
      id = window.setTimeout(error_cb('Connection timeout!'), timeout) if timeout > 0
      
      # Launch!
      _this.$ws.open host
      
  o 'socketBind(Ljava/net/InetAddress;I)V', (rs, _this, address, port) ->
    rs.java_throw rs.get_bs_class('Ljava/io/IOException;'), 'WebSockets doesn\'t know how to bind'

  o 'socketListen(I)V', (rs, _this, port) ->
    rs.java_throw rs.get_bs_class('Ljava/io/IOException;'), 'WebSockets doesn\'t know how to listen'

  o 'socketAccept(Ljava/net/SocketImpl;)V', (rs, _this, s) ->
    rs.java_throw rs.get_bs_class('Ljava/io/IOException;'), 'WebSockets doesn\'t know how to accept'
  
  o 'socketAvailable()I', (rs, _this) ->
    rs.async_op (resume_cb) ->
      window.setTimeout (-> resume_cb(_this.$ws.rQlen())), 1
  
  # TODO: Something isn't working here
  o 'socketClose0(Z)V', (rs, _this, useDeferredClose) ->
    _this.$ws.close()
  
  o 'socketShutdown(I)V', (rs, _this, type) ->
  o 'initProto()V', (rs) ->
  o 'socketSetOption(IZLjava/lang/Object;)V', (rs, _this, cmd, _on, value) ->
  o 'socketGetOption(ILjava/lang/Object;)I', (rs, _this, opt, iaContainerObj) ->
  o 'socketGetOption1(ILjava/lang/Object;Ljava/io/FileDescriptor;)I', (rs, _this, opt, iaContainerObj, fd) ->
    
  o 'socketSendUrgentData(I)V', (rs, _this, data) ->
    # Urgent data is meant to jump ahead of the
    # outbound stream. We keep no notion of this,
    # so queue up the byte like normal
    impl.$ws.send data
]
