// 使用了Express.io这个基于Node.js的Web实时
// 由于要执行一些高级的系统指令，因此要用sudo node app.js来运行这个程序，启动服务器
var path = require('path');
var express_io = require('express.io');
var app = express_io();					//创建app
var spawn = require('child_process').spawn;		//用于异步执行shell命令
var spawnSync = require('child_process').spawnSync;	//用于同步执行shell命令


app.http().io()


app.set('views', path.join(__dirname, 'views'));	//模板路径
app.set('view engine', 'ejs');				//设置模板引擎
app.use(express_io.static('public'));			//公开可访问目录
// Setup the ready route, and emit talk event.
/*	要执行的命令
echo 1 > /proc/sys/net/ipv4/ip_forward
perl ./myconfig.pl
perl ./mynmap.pl xxxx
bash ./itshttp.sh wlp7s0 [det.ip] [route.ip] 
bash ./course.sh wlp7s0 [det.ip] [route.ip]
bash ./http.sh wlp7s0 [det.ip] [route.ip]
*/
var configInfo = null;			//路由配置信息			
ip_forward = spawnSync('echo', ['1', '>', '/proc/sys/net/ipv4/ip_forward']);//开启ip转发
console.log(ip_forward.stdout.toString());
scripts = {'its':'itshttp.sh', 'crs':'course.sh', 'log':'http.sh'};//脚本名称
host = {};
app.io.route('cmd', function(req){	//响应cmd事件
	var args = req.data;
	console.log(args);
	//itshttp = spawn('nmap', ['-sP', '192.168.1.105/24']);
	if (args['op'] == 'kill'){
		kill = spawnSync('kill', ['-9', host[args['dstIP']][args['sel']]]);	//停止之前启动的进程
		req.io.emit('ok');	//cmd事件响应，回复
	} else if (args['op'] == 'nmap'){	//扫描子网下的Host
		nmap = spawn('perl', ['./mynmap.pl', configInfo[configInfo.length-2], configInfo[configInfo.length-1]]);
		nmap.stdout.on('data', function(data){
			dataStr = JSON.stringify(data);
			d = JSON.parse(dataStr);
			req.io.emit('nmap', {	//回复
				message:d
			});
		});
	} else {				//嗅探
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
app.get('/', function(req, res) {	//请求本机信息
	console.log('bad');
	myconfig = spawnSync('perl', ['./myconfig.pl']);
	info = myconfig.stdout.toString().split(' ')
	configInfo = info;
	console.log(info);
    //res.send("ok");
    res.render('index', {info:info});	//客户端收到这个响应之后，会发起一个cmd-nmap事件，服务器扫描子网下所有Host，返回给客户端
    //res.sendfile(__dirname + '/index.html')
})

app.listen(7076)
console.log('listening on http://localhost:7076')
