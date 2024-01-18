class_name GotmMultiplayer

## GotmMultiplayer lets you create peer-to-peer connections without
## worrying about port forwarding.
##
## @tutorial: https://gotm.io/docs/multiplayer

##############################################################
# METHODS
##############################################################

## Get our IP address which other peers can use to join
## our server via GotmMultiplayer.create_client.
## Please note that this address is a virtual address
## and cannot be used with other multiplayer APIs such
## as NetworkedMultiplayerENet.
static func get_address() -> String:
	return await _GotmMultiplayer.get_address()


## Establish a peer-to-peer connection to a server that was 
## created using GotmMultiplayer.create_server.
## The address is the address of the host that created the server.
static func create_client(address: String) -> WebRTCMultiplayerPeer:
	return await _GotmMultiplayer.create_client(address)


## Host a peer-to-peer server.
## Peers can join the server via the host's address.
static func create_server() -> WebRTCMultiplayerPeer:
	return await _GotmMultiplayer.create_server()

