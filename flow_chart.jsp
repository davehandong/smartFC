<%@ page language="java" import="java.util.*" pageEncoding="GBK"%>
<%@ taglib uri="http://java.sun.com/jstl/core" prefix="c" %>

<!doctype html>
<html>
	<head>
		<meta http-equiv="Content-Type" content="charset=GBK" />
		<title>work flow test</title>
		<style type="text/css">
			div{
				width: 100%;
				height: 100%;
				border: 1px solid red;
			}
		</style>
		<script type="application/javascript" src="/js/jquery-1.4.2.min.js"></script>
		<script type="application/javascript">
			var data;
			$(document).ready(function(){
				$.ajax({
					url:'/flowchart/flowChartAction.do',
					dataType:'json',
					type:'POST',
					data:{'method':'toFlowChart','flowId':'<c:out value="${param.flowId}" />','recordId':'<c:out value="${param.recordId}" />'},
					success:function(t){
						data = t;
						init();
						main();
					}
				});
			});
			var canvas;	//canvas Object
			var ctx;	//the 2d Context of the canvas

			var node_width = 129;	//the width of the Node image
			var node_height = 46;	//the height of the Node image
			function init(){
				canvas = document.getElementById('canvas');
				if(canvas.getContext){
					ctx = canvas.getContext('2d');
					ctx.font = '15px 宋体';
				}
			}
			//计算图形间的位置关系
			function drawHandle(lineId){
				var lineObj = data[lineId];
				var pic1 = data[lineObj.PREV_ID];
				var pic2 = data[lineObj.NEXT_ID];
				var gap_x = Math.abs(pic1.POSITION_X - pic2.POSITION_X);
				var gap_y = Math.abs(pic1.POSITION_Y - pic2.POSITION_Y);
				if(gap_x == 0 && gap_y == 0){	//self loop
					var img = new Image();
					img.onload = function(){
						ctx.drawImage(img,parseFloat(pic1.POSITION_X)+55,parseFloat(pic1.POSITION_Y)+30);
					}
					img.src = 'loop.gif';
				}else{
					var xDistance = (node_height/2)*gap_x/gap_y;
					var yDistance = (node_width/2)*gap_y/gap_x;
					var startX=0, startY=0;
					var len = 0;
					if(xDistance <= node_width/2 && gap_y != 0){	// the point of intersection on the X-axis
						var line1 = Math.abs(parseFloat(pic1.POSITION_X) - parseFloat(pic2.POSITION_X));
						var line2 = Math.abs(parseFloat(pic1.POSITION_Y) - parseFloat(pic2.POSITION_Y));
						var angle = getAngle(line1, line2);
						if(parseFloat(pic1.POSITION_Y) < parseFloat(pic2.POSITION_Y)){
							startY = parseFloat(pic1.POSITION_Y) + node_height + 3;
							if(parseFloat(pic1.POSITION_X) < parseFloat(pic2.POSITION_X)){
								angle = Math.PI/2 - angle;
								startX = parseFloat(pic1.POSITION_X) + node_width/2 + xDistance - 5;
							}else{
								angle = Math.PI/2 + angle;
								startX = parseFloat(pic1.POSITION_X) + node_width/2 - xDistance + 5;
							}
						}else if(parseFloat(pic2.POSITION_Y) < parseFloat(pic1.POSITION_Y)){
							startY = parseFloat(pic1.POSITION_Y) - 3;
							if(parseFloat(pic1.POSITION_X) < parseFloat(pic2.POSITION_X)){
								angle = -Math.PI/2 + angle;
								startX = parseFloat(pic1.POSITION_X) + node_width/2 + xDistance - 5;
							}else{
								angle = -Math.PI/2 - angle;
								if(gap_x != 0){
									startX = parseFloat(pic1.POSITION_X) + node_width/2 - xDistance + 5;
								}else{
									startX = parseFloat(pic1.POSITION_X) + node_width/2 - xDistance - 5;
								}
							}
						}
						len = getLineLength(line1,line2,'x');
						if(isNaN(len)){
							len = gap_y - node_height;
						}
						len = len - 21;
					}else if(gap_y != 0){	// the point of intersection on the Y-axis
						var line1 = Math.abs(parseFloat(pic1.POSITION_Y) - parseFloat(pic2.POSITION_Y));
						var line2 = Math.abs(parseFloat(pic1.POSITION_X) - parseFloat(pic2.POSITION_X));
						var angle = getAngle(line1, line2);
						if(parseFloat(pic1.POSITION_Y) < parseFloat(pic2.POSITION_Y)){
							startY = parseFloat(pic1.POSITION_Y) + node_height/2 + yDistance;
							if(parseFloat(pic1.POSITION_X) < parseFloat(pic2.POSITION_X)){
								startX = parseFloat(pic1.POSITION_X) + node_width + 3;
								startY = startY + 5;
							}else{
								angle = Math.PI - angle;
								startX = parseFloat(pic1.POSITION_X) - 3;
								startY = startY - 5;
							}
						}else{
							startY = parseFloat(pic1.POSITION_Y) + node_height/2 - yDistance;
							if(parseFloat(pic1.POSITION_X) < parseFloat(pic2.POSITION_X)){
								angle = -angle;
								startX = parseFloat(pic1.POSITION_X) + node_width + 3;
								startY = startY + 5;
							}else{
								angle = -Math.PI + angle;
								startX = parseFloat(pic1.POSITION_X) - node_width - 3;
								startY = startY - 5;
							}
						}
						len = getLineLength(line1, line2, 'y');
						if(isNaN(len)){
								len = gap_x - node_width;
						}
						len = len - 21;
					}else{
							if(parseFloat(pic1.POSITION_X) < parseFloat(pic2.POSITION_X)){
								startY = parseFloat(pic1.POSITION_Y) + node_height/2 + 3;
								startX = parseFloat(pic1.POSITION_X) + node_width + 3;
								angle = 0;
							}else{
								startY = parseFloat(pic2.POSITION_Y) + node_height/2 - 3;
								startX = parseFloat(pic1.POSITION_X) - 3;
								angle = Math.PI;
							}
							len = Math.abs(parseFloat(pic1.POSITION_X)-parseFloat(pic2.POSITION_X));
							len = len - node_width - 21;
					}
					console.log(pic2.COLOR);
					var arrow = 'line_u.gif';
					if(pic2.COLOR != 'red' && pic1.COLOR != 'red')
						arrow = 'line_c.gif';
					drawLine(angle, len, startX, startY, arrow);
				}
			}
			function drawLine(angle,length,offsetx,offsety,arrow){
				var arch = new Image();
				arch.onload = function(){
					ctx.save();
					ctx.translate(offsetx,offsety);
					ctx.rotate(angle);
					ctx.drawImage(arch,31,0,15,17,length,-8,15,17);
					ctx.lineWidth=4;
					if(arrow =='line_c.gif'){
						ctx.strokeStyle='rgb(255,50,50)';
					}else{
						ctx.strokeStyle='rgb(70,70,70)';
					}
					ctx.beginPath();
					ctx.moveTo(0,0);
					ctx.lineTo(length,0);
					ctx.stroke();
					ctx.restore();
				}
				arch.src = arrow;
			}
			//绘制图形函数
			function drawGraphics(obj){
				if(obj.TYPE == 'picture'){	// draw the node
					var img = new Image();
					img.onload = function(){
						ctx.drawImage(img,obj.POSITION_X,obj.POSITION_Y);
						var text_posx = parseFloat(obj.POSITION_X) + (node_width-obj.TEXT.length*15)/2;
						var text_posy = parseFloat(obj.POSITION_Y) + 29;
						ctx.strokeText(obj.TEXT, text_posx, text_posy);
					}
					if(obj.COLOR == 'red')
						img.src = 'node_u.gif';
					else if(obj.COLOR == 'green')
						img.src = 'node_f.gif';
					else if(obj.COLOR == 'blue')
						img.src = 'node_c.gif';
				}else{	//draw the line
					drawHandle(obj.ID);
				}
			}
			function getAngle(line1, line2){
				var angle = Math.atan(line1/line2);
				return angle;
			}
			function getLineLength(line1, line2, point){
				var len = 0;
				var angle = getAngle(line1, line2);
				if(point == 'x'){
					var hypotenuse = line1/Math.sin(angle);
					var _hypotenuse = node_height/2/line2*hypotenuse;
					len = hypotenuse - _hypotenuse * 2;
				}else{
					var hypotenuse = line1/Math.sin(angle);
					var _hypotenuse = node_width/2/line2*hypotenuse;
					len = hypotenuse - _hypotenuse * 2;
				}
				return len;
			}
			//入口
			function main(){
				for(var curId in data){
					var item = data[curId];	//current picture object
					try{
						drawGraphics(item);
					}catch(err){
						
					}
				}
			}
		</script>
	</head>
	<body>
		<div>
			<canvas id="canvas" width="1200" height="650">
				the browser is not support canvas
			</canvas>
		</div>
	</body>
</html>
