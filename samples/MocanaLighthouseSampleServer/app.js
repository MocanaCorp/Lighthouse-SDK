/*
Project thanks to Ethan Brown
and his book "Web Development with Node & Express"
great book and helped to get this project done and out the door.
*/

var express = require('express');
var fortune = require('./lib/fortune.js');
var formidable = require('formidable');
var fs = require('fs');
var https = require('https');

//setting up CORS option
var allowCrossDomain = function(req, res, next) {
    res.header('Access-Control-Allow-Origin', '*');
    res.header('Access-Control-Allow-Methods', 'GET,PUT,POST,DELETE,OPTIONS');
    res.header('Access-Control-Allow-Headers', 'Content-Type, Authorization, Content-Length, X-Requested-With');

    // intercept OPTIONS method
    if ('OPTIONS' == req.method) {
      res.send(200);
    }
    else {
      next();
    }
};


var options = {
    key: fs.readFileSync('ssl/server/keys/server.key'),
    cert: fs.readFileSync('ssl/server/certificates/server.crt'),
    ca: fs.readFileSync('ssl/ca/ca.crt'),
    requestCert: true,
    rejectUnauthorized: false,


};

var app = express();




//set up the view engine - handlebars
var handlebars = require('express3-handlebars').create({
    defaultLayout:'main',
    helpers: {
        section: function(name, options){
            if(!this._sections) this._sections = {};
            this._sections[name] = options.fn(this);
            return null;
            }
         }
});

app.engine('handlebars', handlebars.engine);
app.set('view engine', 'handlebars');

app.set('port', 3000);

//create an HTTPS listener
https.createServer(options, app).listen(443);

//get user Data from certificate for main page
//This will also render a response indicating
//if no cert was provided from the client
function getUserData(req){
if (req.client.authorized){
  var subject = req.connection.getPeerCertificate().subject;
  return{
    user: subject.CN
  };

  }
else {
    return{user: "NO CERT!"};
}


}

//CORS "middleware"
app.use(allowCrossDomain);

//public static middleware
app.use(express.static(__dirname + '/public'));

//middleware to handle the user data info
app.use(function(req, res, next){
    if(!res.locals.partials) res.locals.partials = {};
    res.locals.partials.userdata = getUserData(req);
    next();
});

//add middleware for body parser - forms parsing
app.use(require('body-parser')());


//routes
app.get('/', function(req, res){
   res.render('home');

});

app.get('/about', function(req, res){

    res.render('about', {fortune: fortune.getFortune() });

});

app.get('/jqtest', function(req, res){

    res.render('jquerytest', {name:'kyle'});

});


app.get('/api/username', function(req, res){

    if (req.client.authorized){
     var subject = req.connection.getPeerCertificate().subject;
        res.setHeader('Content-Type', 'application/json');
        res.json({'user' : subject.CN });
    }
    else {
        res.status(401);
        res.json({'error': 'unauthorized'});
    }


});

app.get('/api/userinfo', function(req, res){

    if (req.client.authorized){
        var subject = req.connection.getPeerCertificate().subject;
        res.setHeader('Content-Type', 'application/json');
        res.json({'user' : {'email' : subject.CN + '@mocana.com', 'phone':'555-555-5555'}});
    }
    else {
        res.status(401);
        res.json({'error': 'unauthorized'});
    }


});

app.get('/headers', function(req,res){
    var ua = '';
    for(var name in req.headers){
       if (name === "user-agent"){
        ua = req.headers[name]
       }
    }
    var headerData = {ipaddr :req.ip , hostname : req.hostname, userAgent : ua};
    res.render('headers', headerData);

});


//custom 404 page
app.use(function(req, res){
    res.status(404);
    res.render('404');

});

//custom 500 page
app.use(function(err, req, res, next){
    console.error(err.stack);
    res.status(500);
    res.render('500');

});

app.listen(app.get('port'), function(){
    console.log('Express started on http://localhost:' +
        app.get('port') + '; press Ctrl+C to terminate.');

})
