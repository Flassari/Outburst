class Player
  constructor: (@scene) ->
    loader = new THREE.JSONLoader()
    loader.load
      model: "models/figure.js"
      callback: (geo) => 
        @makeModel(scene, geo)
  
  
  makeModel: (scene, geometry) ->
    geometry.materials[0][0].shading = THREE.FlatShading
    geometry.materials[0][0].morphTargets = true
    @model = new AnimatedMesh geometry, [ new THREE.MeshFaceMaterial() ],
      walk:
        firstKeyframeIndex: 0
        duration: 1500
        keyframes: 27
    @model.scale.x = @model.scale.y = @model.scale.z = 20
    @model.rotation.x = 90
    scene.addObject @model
    @model.playAnimation "walk"
  
  update: (delta) -> 
    if @model
      @model.position.y += delta * 200 if input.up
      @model.position.y -= delta * 200 if input.down
      @model.position.x -= delta * 200 if input.left
      @model.position.x += delta * 200 if input.right
      @model.updateAnimation (delta)
      @model.isPaused = not (input.up or input.down or input.left or input.right)
  
  
  
# export
@Player = Player