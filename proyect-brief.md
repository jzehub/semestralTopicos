# Proyecto Final Tópicos Especiales 1
CRUD	en	AWS	con	backend	multi-zona,	Load	Balancer,	base	de	datos	administrada	y	
frontend	consumiendo	el	API.
## Contexto
Como	equipo	de	desarrollo	cloud-native,	deben	diseñar	y	entregar	una	aplicación	mínima	
pero	completa	(Create–Read–Update–Delete)	para	contenedores	en	AWS,	con	alta	
disponibilidad	a	nivel	de	zona	de	disponibilidad	y	separación	por	capas.
## Objetivo General
Construir	un	producto	funcional	que	exponga	un	API	REST	detrás	de	un	Application	Load	
Balancer,	persistiendo	datos	en	un	motor	administrado	de	AWS	y	con	un	frontend	web	que	
consuma	dicho	API.
## Alcance Mínimo (obligatorio)
1. **Backend**:	Exponer	un	API	REST	usando	fargate	para	un	recurso	(ej.:	Items,	Productos,	
Tareas,	Contactos),	con	endpoints	/items:	POST,	GET,	GET	/:id,	PUT	/:id,	DELETE	/:id.	
Despliegue	en	2	AZ	mínimo	y	detrás	de	un	ALB.
1. **Base	de	Datos**:	Usar	un	servicio	administrado	en	AWS	(RDS	MySQL/PostgreSQL	o	Aurora	
Serverless	v2).	
1. **Frontend**:	Aplicación	web	(framework	libre)	que	permita	crear,	listar,	editar	y	eliminar	el	
recurso	anterior	consumiendo	el	API.
# Requisitos Técnicos
Alta	disponibilidad,	balanceo	con	ALB,	red	con	VPC/subredes	públicas	y	privadas,	seguridad	
con	grupos	restringidos,	
# Demostración Obligatoria
Demostrar	la	creación,	edición,	eliminación	y	persistencia	de	registros	desde	el	frontend	
hacia	el	backend	y	la	base	de	datos. Una	presentación	explicando	el	software	y	elementos	
usados
# Restricciones
No	usar	SQLite,	no	exponer	DB	a	Internet,	