# gd_multiplayer_capsule

# Information:
  Simple test on lobby and spawn position. Using the capsule 3D for Character3D controller and inputs.
	
# Features:
- Host
- Join
- Lobby
- Spawn Position Test
- Disconnected
	- check for if Node3D player exist to delete.
- Player
	- Control movement key board default W,A,S,D
	- Camera rotate = Mouse Input
	- Jump =  Space Key
	- Escape Key = toggle mouse capture input

# Network:
```
multiplayer.connection_failed.connect(_on_connected_fail)
```
 Note this try to connect to the server. For time out is about 30 sec if fail to connect.



# Notes:
- This simple sample test.
- Auth and other RPC call not been used.

# credits:
- https://www.youtube.com/watch?v=WiHjHQe8PGg
	- simple lobby
