class CameraLayer extends Layer
  constructor: (options = {}) ->
    super(options)

    @_camera = null
    @_stream = null

    @_video = document.createElement("video")
    @_video.autoplay = true
    @_video.muted = true

    _.extend @_video.style,
      width: "100%"
      height: "100%"
      objectFit: "cover"

    @_element.appendChild(@_video)

    @autoflip = true
    @facing = "environment"
    @clip = true;
    @backgroundColor = "rgba(0, 0, 0, 1.0)"

  @define "facing",
    get: -> @_facing
    set: (value) ->
      @_facing = value if value == "user" || value == "environment"

  @define "autoflip",
    get: -> @_autoflip
    set: (value) -> @_autoflip = !!value

  toggleFacing: ->
    switch @facing
      when "user" then @facing = "environment"
      when "environment" then @facing = "user"

  capture: (width = @width, height = @height, ratio = window.devicePixelRatio) ->
    canvas = document.createElement("canvas")
    canvas.width = ratio * width
    canvas.height = ratio * height

    context = canvas.getContext("2d")
    @draw(context)

    canvas.toDataURL("image/png")

  draw: (context) ->
    return unless context

    cover = (srcW, srcH, dstW, dstH) ->
      scaleX = dstW / srcW
      scaleY = dstH / srcH
      scale = if scaleX > scaleY then scaleX else scaleY
      width: srcW * scale, height: srcH * scale

    {videoWidth, videoHeight} = @_video

    clipBox = width: context.canvas.width, height: context.canvas.height
    layerBox = cover(@width, @height, clipBox.width, clipBox.height)
    videoBox = cover(videoWidth, videoHeight, layerBox.width, layerBox.height)

    x = (clipBox.width - videoBox.width) / 2
    y = (clipBox.height - videoBox.height) / 2

    context.drawImage(@_video, x, y, videoBox.width, videoBox.height)

  start: ->
    @_getSources (sources) =>
      camera = _.find sources, kind: "video", facing: @_facing
      camera ?= _.find sources, kind: "video"
      oldId = @_camera?.id
      newId = camera?.id

      return if newId is oldId

      @_camera = camera
      @_requestCamera()

  _requestCamera: ->
    @_video.src = ''
    @_stream?.stop()

    @_getUserMedia {video: true, audio: true},
      (stream) =>
        @_stream = stream
        @_video.src = URL.createObjectURL(stream)
        @_flip()
      (error) =>
        console.error(error)

  _getSources: do ->
    MediaStreamTrack = window.MediaStreamTrack ? {}
    getSources = MediaStreamTrack.getSources
    getSourcesFallback = -> # do nothing
    (getSources ? getSourcesFallback).bind(MediaStreamTrack)

  _getUserMedia: do ->
    getUserMedia = navigator.getUserMedia ? navigator.webkitGetUserMedia
    getUserMediaFallback = -> # do nothing
    (getUserMedia ? getUserMediaFallback).bind(navigator)

  _flip: ->
    x = if @_camera.facing == "user" then -1 else 1
    @_video.style.webkitTransform = "scale(" + x + ",1)"

  _supportUserMedia: ->
    getUserMedia = navigator.getUserMedia ? navigator.webkitGetUserMedia
    createObjectURL = window.URL?.createObjectURL
    _.isFunction(getUserMedia) and _.isFunction(createObjectURL)


module.exports = CameraLayer if module?
Framer.CameraLayer = CameraLayer
