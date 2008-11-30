class host-puppetmaster::users inherits host-base::users {
	realize( User["root"] ) #make sure that user root is managed. 
	User ["root"] {password => 'hashhash'}
}
