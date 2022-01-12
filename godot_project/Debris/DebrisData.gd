extends Node

enum CollisionLayer {
	NEUTRAL		=	0x00,
	STATION		=	0x01,
	LEADER		=	0x02,
	FOLLOWER		=	0x04,
	PROJECTILE	=	0x08
}


enum CollisionMask {
	NEUTRAL		=	0x0
	STATION		=	CollisionLayer.LEADER,
	LEADER		=	CollisionLayer.STATION | CollisionLayer.PROJECTILE,
	FOLLOWER		=	CollisionLayer.PROJECTILE,
	PROJECTILE	=	CollisionLayer.FOLLOWER | CollisionLayer.LEADER
}
