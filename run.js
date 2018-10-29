const express = require('express');
const app = express();
const path = require('path');

app.listen(8000, () => {
	console.log('App is listening on port 8000');
})

// Setting the views folder to call files from
app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'views'));

// Calling the profile.ejs file from the views folder when on /u
app.get('/', (req, res) => { 
	res.render('index');
});