var path = require('path');
var express_io = require('express.io');
var app = express_io();
var spawn = require('child_process').spawn;
var spawnSync = require('child_process').spawnSync;

function Array2String(array) {
	var result = "";
	for (var i = 0; i < array.length; i++) {
	result += String.fromCharCode(parseInt(array[i], 10));
	}
	return result;
};

app.http().io()


app.set('views', path.join(__dirname, 'views'));
app.set('view engine', 'ejs');
app.use(express_io.static('public'));
// Setup the ready route, and emit talk event.
/*
echo 1 > /proc/sys/net/ipv4/ip_forward
perl ./myconfig.pl
perl ./mynmap.pl xxxx
bash ./itshttp.sh wlp7s0 [det.ip] [route.ip] 
bash ./course.sh wlp7s0 [det.ip] [route.ip]
bash ./http.sh wlp7s0 [det.ip] [route.ip]
*/
var configInfo = null;
ip_forward = spawnSync('echo', ['1', '>', '/proc/sys/net/ipv4/ip_forward']);
console.log(ip_forward.stdout.toString());
scripts = {'its':'itshttp.sh', 'crs':'course.sh', 'log':'http.sh'};
host = {};
app.io.route('cmd', function(req){
	var args = req.data;
	console.log(args);
	//itshttp = spawn('nmap', ['-sP', '192.168.1.105/24']);
	if (args['op'] == 'kill'){
		kill = spawnSync('kill', ['-9', host[args['dstIP']][args['sel']]]);
		req.io.emit('ok');
	} else if (args['op'] == 'nmap'){
		nmap = spawn('perl', ['./mynmap.pl', configInfo[configInfo.length-2], configInfo[configInfo.length-1]]);
		nmap.stdout.on('data', function(data){
			dataStr = JSON.stringify(data);
			d = JSON.parse(dataStr);
			req.io.emit('nmap', {
				message:d
			});
		});
	} else {
	    cmd = spawn('bash', [scripts[args['sel']], configInfo[0], 
	    	args['dstIP'], configInfo[5]]);
	    if (host[args['dstIP']] == null){
	    	host[args['dstIP']] = {};
	    }
	    host[args['dstIP']][args['sel']] = cmd.pid;
		cmd.stdout.on('data', function (data) {
			if (args['sel']=='crs'){
				  req.io.emit(args['sel'], {
				  	message: {
				  		'data':data.toString(),
				  		'ip':args['dstIP'],
				  		'sel':args['sel']
				  	}
				  });
			}
			console.log(args['dstIP']);
			dataStr = JSON.stringify(data);
			d = JSON.parse(dataStr);
			d['ip'] = args['dstIP'];
			d['sel'] = args['sel'];
			console.log(d);

		/*		data['ip'] = args['dstIP']; // does not work
			  	console.log('stdout:\n' + data);
			  	console.log(JSON.stringify(data));*/
			
		  	req.io.emit(args['sel'], {
				message: d
			});
		});

		cmd.stderr.on('data', function (data) {
		  console.log('stderr:\n' + data);
		});

		cmd.on('close', function (code) {
		  console.log('child process exited with code ' + code);
		});
	}
});
// Send the client html.
app.get('/', function(req, res) {
	console.log('bad');
	myconfig = spawnSync('perl', ['./myconfig.pl']);
	info = myconfig.stdout.toString().split(' ')
	configInfo = info;
	console.log(info);
    //res.send("ok");
    res.render('index', {info:info})
    //res.sendfile(__dirname + '/index.html')
})

app.listen(7076)
console.log('listening on http://localhost:7076')