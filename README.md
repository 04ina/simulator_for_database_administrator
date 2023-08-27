# simulator for database administrator
## Installation
> git clone  
> cd simulator_for_database_administrator  
> make install  
## Setup
Run the following SQL query on the database:  
> CREATE EXTENSION sfda;
Specify the schema that the extension roles will have access to:  
> SELECT addschema('schema_name');  
> 
