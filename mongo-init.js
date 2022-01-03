
db.createUser(
{
    user: "main",
    pwd:  "question123", 
    roles: [ { role: "readWrite", db: "aq" },
             { role: "readWrite", db: "bm" },
    ]
})