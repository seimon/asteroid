dev=0
ver="0.16" -- 2022/07/01

poke(0X5F5C, 12) poke(0X5F5D, 3) -- Input Delay(default 15, 4)
poke(0x5f2d, 0x1) -- Use Mouse input

-- <class helper> --------------------
function class(base)
	local nc={}
	if (base) setmetatable(nc,{__index=base}) 
	nc.new=function(...) 
		local no={}
		setmetatable(no,{__index=nc})
		local cur,q=no,{}
		repeat
			local mt=getmetatable(cur)
			if not mt then break end
			cur=mt.__index
			add(q,cur,1)
		until cur==nil
		for i=1,#q do
			if (rawget(q[i],'init')) rawget(q[i],'init')(no,...)
		end
		return no
	end
	return nc
end

-- event dispatcher
event=class()
function event:init()
	self._evt={}
end
function event:on(event,func,context)
	self._evt[event]=self._evt[event] or {}
	-- only one handler with same function
	self._evt[event][func]=context or self
end
function event:remove_handler(event,func,context)
	local e=self._evt[event]
	if (e and (context or self)==e[func]) e[func]=nil
end
function event:emit(event,...)
	for f,c in pairs(self._evt[event]) do
		f(c,...)
	end
end

-- sprite class for scene graph
sprite=class(event)
function sprite:init()
	self.children={}
	self.parent=nil
	self.x=0
	self.y=0
end
function sprite:set_xy(x,y)
	self.x=x
	self.y=y
end
function sprite:get_xy()
	return self.x,self.y
end
function sprite:add_child(child)
	child.parent=self
	add(self.children,child)
end
function sprite:remove_child(child)
	del(self.children,child)
	child.parent=nil
end
function sprite:remove_self()
	if self.parent then
		self.parent:remove_child(self)
	end
end
-- logical xor
function lxor(a,b) return not a~=not b end
-- common draw function
function sprite:_draw(x,y,fx,fy)
	spr(self.spr_idx,x+self.x,y+self.y,self.w or 1,self.h or 1,lxor(fx,self.fx),lxor(fy,self.fy))
end
function sprite:show(v)
	self.draw=v and self._draw or nil
end
function sprite:render(x,y,fx,fy)
	if (self.draw) self:draw(x,y,fx,fy)
	for i=1,#self.children do
		self.children[i]:render(x+self.x,y+self.y,lxor(fx,self.fx),lxor(fy,self.fy))
	end
end
function sprite:emit_update()
	self:emit("update")
	for i=1,#self.children do
		local child=self.children[i]
		if child then child:emit_update() end
	end
end



-- <log, system info> --------------------
log_d=nil
log_counter=0
function log(...)
	local s=""
	for i,v in pairs{...} do
		s=s..v..(i<#{...} and "," or "")
	end
	if log_d==nil then log_d=s
	else log_d=sub(s.."\n"..log_d,1,200) end
	log_counter=3000
end
function print_log()
	if(log_d==nil or log_counter<=1) log_d=nil return
	log_counter-=1
	?log_d,2,2,0
	?log_d,1,1,8
end
function print_system_info()
	local cpu=round(stat(1)*10000)
	local s=(cpu\100).."."..(cpu%100\10)..(cpu%10).."%"
	local mem=tostr(stat(0))
	if #tostr(mem%1)<6 then
		for i=#tostr(mem%1)+1,6 do mem=mem.."0" end
	end
	printa(s,128,2,0,1) printa(s,127,1,8,1)
	printa(mem,128,8,0,1) printa(mem,127,7,8,1)
end



-- <utilities> --------------------
function round(n) return flr(n+.5) end
function swap(v) if v==0 then return 1 else return 0 end end -- 1 0 swap
function clamp(a,min_v,max_v) return min(max(a,min_v),max_v) end
function rndf(lo,hi) return lo+rnd()*(hi-lo) end -- random real number between lo and hi
function rndi(n) return round(rnd()*n) end -- random int
function printa(t,x,y,c,align,shadow) -- 0.5 center, 1 right align
	x-=align*4*#(tostr(t))
	if (shadow) ?t,x+1,y+1,0
	?t,x,y,c
end



-- <shape data> --------------------

function str_to_arr(str,scale)
	local arr=split(str,",")
	if scale then
		for i=1,#arr do
			if(arr[i]!="x") arr[i]=arr[i]*scale
		end
	end
	return arr
end
shape_ufo=str_to_arr("6,2,0,5,-6,2,6,2,2,-1,-2,-1,-6,2,-2,-1,-2,-3,2,-3,2,-1")
shape_ship=str_to_arr("4,0,-4,4,-2,0,-4,-4,4,0")
shape_ast1=str_to_arr("4,0,2,-1,2,-3,-1,-4,-2,-2,-4,0,-2,1,-3,2,-2,4,0,3,2,4,4,0",2.3)
shape_ast2=str_to_arr("4,0,2,4,0,3,-2,4,-4,2,-4,-2,-2,-4,0,-2,3,-3,4,0",1.5)
shape_ast3=str_to_arr("4,2,2,4,-4,0,-2,-4,3,-3,4,2",0.85)
s_title_str="0,6,3,0,6,6,10,6,10,4,6,2,6,0,10,0,14,0,x,x,12,0,12,6,x,x,1,4,5,4" -- AST
s_title_str=s_title_str..",x,x,19,0,15,0,15,6,19,6,x,x,15,3,18,3" -- E
s_title_str=s_title_str..",x,x,20,6,20,0,24,0,24,3,21,3,24,6,x,x,25,6,28,6,29,4,29,0,26,0,25,2,25,6" -- RO
s_title_str=s_title_str..",x,x,30,0,32,0,x,x,31,0,31,6,x,x,30,6,32,6" -- I
s_title_str=s_title_str..",x,x,33,6,36,6,37,4,37,2,36,0,33,0,33,6,x,x,38,6,42,6,42,4,38,2,38,0,42,0" -- DS
s_title=str_to_arr(s_title_str,2.5)
s_demake=str_to_arr("0,0,0,6,3,6,4,4,4,2,3,0,0,0,x,x,9,0,5,0,5,6,10,6,10,0,13,6,16,0,16,6,19,0,22,6,22,0,x,x,31,0,27,0,27,6,31,6,x,x,5,3,8,3,x,x,17,4,21,4,x,x,26,0,22,3,26,6,x,x,27,3,30,3",2.5)
s_2022=str_to_arr("0,0,4,0,4,2,0,4,0,6,4,6,x,x,6,0,5,2,5,6,8,6,9,4,9,0,6,0,x,x,6,5,8,1,x,x,10,0,14,0,14,2,10,4,10,6,14,6,x,x,15,0,19,0,19,2,15,4,15,6,19,6",2.5)
s_game=str_to_arr("4,0,1,0,0,2,0,6,4,6,4,3,2,3,x,x,4,6,7,0,10,6,10,0,13,6,16,0,16,6,x,x,5,4,9,4,x,x,21,0,17,0,17,6,21,6,x,x,17,3,20,3",2.5)
s_over=str_to_arr("4,0,4,4,3,6,0,6,0,2,1,0,4,0,x,x,5,0,8,6,11,0,x,x,16,0,12,0,12,6,16,6,x,x,12,3,15,3,x,x,17,6,17,0,21,0,21,3,18,3,21,6",2.5)

s_circle={}
for i=0,24 do
	local r=i/24
	local x,y=cos(r)*40,sin(r)*40
	add(s_circle,x)
	add(s_circle,y)
end




-- <space> --------------------
space=class(sprite)
function space:init(is_front)
	self.spd_x=0.1
	self.spd_y=0
	self.stars={}
	self.particles={}

	local function make_star(i,max,base_spd)
		return {
			x=rnd(127),
			y=rnd(127),
			spd=base_spd+i/max*base_spd,
			size=1+rnd(1)
		}
	end
	if is_front then
		for i=1,12 do add(self.stars,make_star(i,12,3)) end
	else
		for i=1,50 do add(self.stars,make_star(i,50,1)) end
	end

	self:show(true)
	self:on("update",self.on_update)
end

ptcl_size="11223334443332211000"
ptcl_thrust_col="c77aa99882211211"
ptcl_back_col="77666dd1d111"
ptcl_fire_col="89a7"
ptcl_size_explosion="56776655443321111000"
ptcl_col_explosion="77aaa99988888989994444441111"
ptcl_col_explosion_dust="77982"
ptcl_col_hit="cc7a82"

function space:_draw()
	-- stars
	for v in all(self.stars) do
		--[[ local x=v.x-self.spd_x*v.spd
		local y=v.y+self.spd_y*v.spd
		v.x=x>129 and x-129 or x<-2 and x+129 or x
		v.y=y>129 and y-129 or y<-2 and y+129 or y
		local x2=v.x+cx
		local y2=v.y+cy
		x2=x2>129 and x2-129 or x2<-2 and x2+129 or x2
		y2=y2>129 and y2-129 or y2<-2 and y2+129 or y2
		if v.size>1.9 then circfill(x2,y2,1,v.c)
		else pset(x2,y2,v.c) end ]]

		-- v.x=v.x-self.spd_x*v.spd
		-- v.y=v.y+self.spd_y*v.spd
		--[[ coord_loop(v)
		local v2={x=v.x+cx,y=v.y+cy}
		coord_loop(v2)
		if v.size>1.9 then circfill(v2.x,v2.y,1,v.c)
		else pset(v2.x,v2.y,v.c) end ]]

		local x=v.x-self.spd_x*v.spd
		local y=v.y+self.spd_y*v.spd
		v.x=x>129 and x-129 or x<-2 and x+129 or x
		v.y=y>129 and y-129 or y<-2 and y+129 or y

		local c=rnd()<0.001 and 13 or 1
		if v.size>1.9 then circfill(v.x,v.y,1,c)
		else pset(v.x,v.y,c) end
	end

	-- particles
	for i,v in pairs(self.particles) do
		if v.type=="thrust" then
			pset(v.x,v.y,11)
			v.x+=v.sx+rnd(4)-2
			v.y+=v.sy+rnd(4)-2
			v.sx*=0.93
			v.sy*=0.93
			if(v.age>6) del(self.particles,v)

		--[[ elseif v.type=="thrust-back" then
			circfill(v.x,v.y,
				sub(ptcl_size,v.age,_)*0.7,
				tonum(sub(ptcl_back_col,v.age,_),0x1))
			v.x+=v.sx-self.spd_x+rnd(2)-1
			v.y+=v.sy+self.spd_y+rnd(2)-1
			v.sx*=0.93
			v.sy*=0.93
			if(v.age>16) del(self.particles,v) ]]

	elseif v.type=="bullet" or v.type=="bullet_ufo" then
			v.x+=v.sx
			v.y+=v.sy
			coord_loop(v)
			pset(v.x,v.y,11)
			if(v.age>v.age_max) del(self.particles,v)

			if v.type=="bullet" then
				-- hit test bullet & enemy
				local killed={}
				for e in all(_enemies.list) do
					local dist=(e.size==4) and 7 or (e.size==1) and 9 or (e.size==2) and 7 or 5
					if abs(v.x-e.x)<=dist and abs(v.y-e.y)<=dist and get_dist(v.x,v.y,e.x,e.y)<=dist then
						score_up(e.size)
						if(e.size<3) add(killed,{x=e.x,y=e.y,size=e.size})
						local shape=(e.size==1) and shape_ast1 or (e.size==2) and shape_ast2 or shape_ast3
						add_break_eff(e.x,e.y,shape)
						add_explosion_eff(e.x,e.y,v.sx,v.sy)
						del(self.particles,v)
						del(_enemies.list,e)
						sfx(3,3)
					end
				end
				for e in all(killed) do
					_enemies:add(e.x+1,e.y+1,e.size+1)
					_enemies:add(e.x-1,e.y-1,e.size+1)
				end
			else
				-- ship과 충돌 처리
				local dist=4+(_ship.use_shield and 5 or 0)
				local x,y=_ship.x,_ship.y
				if abs(v.x-x)<=dist and abs(v.y-y)<=dist and get_dist(v.x,v.y,x,y)<=dist then
					if _ship.use_shield then add_explosion_eff(v.x,v.y,v.sx,v.sy)
					else _ship:kill() end
					del(self.particles,v)
				end
			end

		elseif v.type=="explosion" then
			circ(v.x,v.y,sub(ptcl_size_explosion,v.age,_)*v.size,11)
			v.x+=v.sx+rnd(1)-0.5
			v.y+=v.sy+rnd(1)-0.5
			v.sx*=0.9
			v.sy*=0.9
			if(v.age>18) del(self.particles,v)

		elseif v.type=="explosion_dust" then
			pset(v.x,v.y,11)
			v.x+=v.sx
			v.y+=v.sy
			v.sx*=0.9
			v.sy*=0.9
			if(v.age>24) del(self.particles,v)

		elseif v.type=="hit" then
			pset(v.x,v.y,11)
			v.x+=v.sx
			v.y+=v.sy
			v.sx*=0.94
			v.sy*=0.94
			if(v.age>12) del(self.particles,v)

		elseif v.type=="line" then
			line(v.x+v.x1,v.y+v.y1,v.x+v.x2,v.y+v.y2,v.c)
			local p1,p2=rotate(v.x1,v.y1,v.r),rotate(v.x2,v.y2,v.r)
			v.x+=v.sx
			v.y+=v.sy
			v.x1=p1.x
			v.y1=p1.y
			v.x2=p2.x
			v.y2=p2.y
			v.r*=0.99
			v.sx*=0.99
			v.sy*=0.99
			if(v.age>v.age_max) del(self.particles,v)

		elseif v.type=="circle" then
			local r=v.r1+(v.r2-v.r1)*(v.age/v.age_max)
			circ(v.x,v.y,r,11)
			if(v.age>v.age_max) del(self.particles,v)

		elseif v.type=="debug_line" then
			local c=6+v.x1%6
			line(v.x1,v.y1,v.x2,v.y2,c)
			circfill(v.x1,v.y1,1,c)
			if(v.age>60) del(self.particles,v)

		end
		v.age+=1
	end
end

function space:on_update()
end



-- <ship> --------------------
ship=class(sprite)
function ship:init()
	self.x=64
	self.y=64
	self.spd=0
	self.spd_x=0
	self.spd_y=0
	self.spd_max=1.2
	self.angle=0
	self.angle_acc=0
	self.angle_acc_power=0.0009
	self.thrust=0
	self.thrust_acc=0
	self.thrust_power=0.0007
	self.thrust_max=1.0
	self.tail={x=0,y=0}
	self.head={x=0,y=0}
	self.fire_spd=1.6
	self.fire_intv=0
	self.fire_intv_full=14-(dev==1 and 12 or 0)
	-- self.bomb_spd=0.7
	-- self.bomb_intv=0
	-- self.bomb_intv_full=60
	self.use_shield=false
	self.shield_timer=120
	self.shield_refill_timer=300
	self.is_killed=false
	-- self.hit_count=0
	-- self:show(true)
	self:on("update",self.on_update)
end

function ship:_draw()
	local x,y=self.x,self.y
	draw_shape(shape_ship,x,y,11,self.angle)
	local x0=cos(self.angle)
	local y0=sin(self.angle)
	self.tail.x=x-x0*6
	self.tail.y=y-y0*6	
	self.head.x=x+x0*8
	self.head.y=y+y0*8

	if self.use_shield then
		circ(x,y,8,11)
	end

	-- 변두리에 있을 때 맞은편에도 그림
	if x<4 then draw_shape(shape_ship,x+130,y,11,self.angle) end
	if y<4 then draw_shape(shape_ship,x,y+130,11,self.angle) end
	if x>123 then draw_shape(shape_ship,x-130,y,11,self.angle) end
	if y>123 then draw_shape(shape_ship,x,y-130,11,self.angle) end
end

function ship:on_update()

	if not self.draw then return end
	
	-- rotation
	if btn(0) then self.angle_acc+=self.angle_acc_power
	elseif btn(1) then self.angle_acc-=self.angle_acc_power end
	local a=self.angle+self.angle_acc
	self.angle=a>1 and a-1 or a<0 and a+1 or a
	self.angle_acc*=0.93
	if(abs(self.angle_acc)<0.0005) self.angle_acc=0

	-- acceleration
	if btn(2) then
		self.thrust_acc+=self.thrust_power
	end
	self.thrust=clamp(self.thrust+self.thrust_acc,-self.thrust_max,self.thrust_max)
	self.thrust_acc*=0.8
	self.thrust*=0.9
	local thr_x=cos(self.angle)*self.thrust
	local thr_y=sin(self.angle)*self.thrust
	self.spd_x+=thr_x
	self.spd_y+=thr_y
	self.spd_x*=0.99
	self.spd_y*=0.99

	-- local tx=self.x+self.spd_x
	-- local ty=self.y+self.spd_y
	-- self.x=tx>131 and tx-131 or tx<-4 and tx+131 or tx
	-- self.y=ty>131 and ty-131 or ty<-4 and ty+131 or ty
	self.x+=self.spd_x
	self.y+=self.spd_y
	coord_loop(self)

	-- fire
	self.fire_intv-=1
	if btn(4) and self.fire_intv<=0 then

		if(dev) score_up(4)

		sfx(23,-1)
		self.fire_intv=self.fire_intv_full
		local fire_spd_x=cos(self.angle)*self.fire_spd+self.spd_x*1.4
		local fire_spd_y=sin(self.angle)*self.fire_spd+self.spd_y*1.4
		add(_space.particles,
		{
			type="bullet",
			x=self.head.x,
			y=self.head.y,
			sx=fire_spd_x,
			sy=fire_spd_y,
			age_max=40,
			age=1
		})
	end

	-- shield
	-- TODO: 동작 제대로 구현해야 함
	if btn(5) and self.shield_timer>0 then
		self.use_shield=true
		self.shield_timer-=1
	else
		self.use_shield=false
		if self.shield_refill_timer>0 then
			self.shield_refill_timer-=1
		else
			self.shield_refill_timer=300
			self.shield_timer=120
		end
	end

	-- add effect
	if self.thrust_acc>0 then
		sfx(4,2)
		add(_space.particles,
		{
			type="thrust",
			x=self.tail.x-1+rnd(2),
			y=self.tail.y-1+rnd(2),
			sx=-thr_x*130,
			sy=-thr_y*130,
			age=1
		})
	elseif self.thrust_acc<-0.0001 then
		sfx(5,2)
		add(_space.particles,
		{
			type="thrust-back",
			x=self.head.x-2+rnd(4),
			y=self.head.y-2+rnd(4),
			sx=-thr_x*120,
			sy=-thr_y*120,
			age=1
		})
	else
		sfx(-1,2)
	end

	-- speed limit
	local spd=sqrt(self.spd_x^2+self.spd_y^2)
	if spd>self.spd_max then
		local r=self.spd_max/spd
		self.spd_x*=r
		self.spd_y*=r
	end

	-- hit test with enemies
	
	-- for i,e in pairs(_enemies.list) do
	local x,y=self.x,self.y
	for e in all(_enemies.list) do
		local dist=(e.size==1) and 7+4 or (e.size==2) and 5+4 or 3+4
		if(self.use_shield) dist+=3
		if abs(e.x-x)<=dist and abs(e.y-y)<=dist and get_dist(e.x,e.y,x,y)<=dist then	
			
			-- 단순 속도 교환 방식
			--[[ local sx=e.spd_x*1.2
			local sy=e.spd_y*1.2
			e.spd_x=self.spd_x
			e.spd_y=self.spd_y
			e.x+=e.spd_x
			e.y+=e.spd_y
			self.spd_x=sx
			self.spd_y=sy
			sfx(2,3)
			local d=atan2(e.x-x,e.y-y)
			add_hit_eff((x+e.x)/2,(y+e.y)/2,d) ]]

			if self.use_shield then
				-- 충돌 방향만 보고 서로 반대로 밀기
				local d=atan2(e.x-x,e.y-y)
				local sx,sy=cos(d)*0.5,sin(d)*0.5
				e.spd_x=sx
				e.spd_y=sy
				e.x+=sx*2
				e.y+=sy*2
				self.spd_x=-sx
				self.spd_y=-sy
				self.x-=sx*2
				self.y-=sy*2
				sfx(2,3)
				add_hit_eff((x+e.x)/2,(y+e.y)/2,d)
			elseif not self.is_killed then
				self:kill()
			end

		end
	end
end

function ship:kill()
	if(self.is_killed) return

	sfx(3,3)
	sfx(-1,2) -- 분사음 강제로 끔
	local x,y=self.x,self.y
	add_explosion_eff(x,y,self.spd_x,self.spd_y,2,40)
	add_break_eff(x,y,shape_ship,1,60)
	add_break_eff(x,y,shape_ship,2,60)

	self.is_killed=true
	self:show(false)
	self.revive_count=150
	self:on("update",self.on_killed)
end

function ship:on_killed()
	self.revive_count-=1
	if(self.revive_count==60 and gg.ships>=1) add_circle_eff(64,64,4,40,60)
	if self.revive_count<=0 then
		gg.ships-=1
		if gg.ships>=0 then
			add_break_eff(64,64,s_circle,0.8,20)
			self:revive()
		else
			_enemies:kill_all()
			gg.is_gameover=true
			gg.key_wait=30
		end
		self:remove_handler("update",self.on_killed)
	end
end

function ship:reset()
	self.x,self.y=64,64
	self.spd=0
	self.spd_x,self.spd_y=0,0
	self.angle=0
	self.angle_acc=0
	self.thrust=0
	self.thrust_acc=0
	self.is_killed=false
	-- todo: 쉴드도 리셋해야 함
end

function ship:revive()
	_enemies:kill_center(40)
	self:reset()
	self:show(true)
	add_explosion_eff(64,64,0,0,2,40)
end



-- <enemies> --------------------
enemies=class(sprite)
function enemies:init()
	self.list={}
end

function enemies:group_update() -- 소행성 수를 일정하게 맞춰준다

	if gg.is_gameover then return end

	local c1,c2,c3,c4=0,0,0,0
	for e in all(self.list) do
		if(e.size==1) c1+=1
		-- if(e.size==2) c2+=1
		-- if(e.size==3) c3+=1
		if(e.size==4) c4+=1
	end

	local df=2+gg.score2 -- 난이도(큰 소행성이 리필되는 수 / 2~무제한???)
	if c1<df and #self.list<10 then
		local r=rnd()
		local x=cos(r)*90
		local y=sin(r)*90
		self:add(64+x,64+y,1,-x*0.003,-y*0.003,true)
	end

	-- 10000점마다 UFO 출현
	if c4<1 and gg.score1\1000+gg.score2*10>gg.ufo_born then
		self:add(-10,30+rndi(40),4,0.2,0,true)
		gg.ufo_born+=1
	end

end

function enemies:_draw()

	-- 주기적으로 소행성 수량 조절
	if(f%60==0) self:group_update()

	for i,e in pairs(self.list) do
		e.x+=e.spd_x
		e.y+=e.spd_y
		e.angle=value_loop(e.angle+e.spd_r,0,1)
		
		if e.is_yeanling then
			if(e.x>5 and e.x<122 and e.y>5 and e.y<122) e.is_yeanling=false
		else
			coord_loop(e)
		end

		if e.size==4 then
			spr(14,e.x-5,e.y-4,2,2)
			pset(e.x-4+round(e.count/90*4)*2,e.y,11)
			e.count+=1
			if e.count>=90 then
				e.count=0
				sfx(23,-1)
				local angle=atan2(_ship.x-e.x+rnd(10)-5,_ship.y-e.y+rnd(10)-5)
				local sx=cos(angle)*0.5
				local sy=sin(angle)*0.5
				add(_space.particles,
				{
					type="bullet_ufo",
					x=e.x+sx*14,
					y=e.y+sy*14,
					sx=sx,
					sy=sy,
					age_max=100,
					age=1
				})
			end

			-- UFO는 화면 밖으로 나가면 사라짐
			if(e.x>130) del(self.list,e)

		else
			local shape=(e.size==1) and shape_ast1 or (e.size==2) and shape_ast2 or shape_ast3
			draw_shape(shape,e.x,e.y,11,e.angle)

			-- 변두리에 있을 때 맞은편에도 그림(생성 초기는 제외)
			if not e.is_yeanling then
				if e.x<4 then draw_shape(shape,e.x+130,e.y,11,e.angle) end
				if e.y<4 then draw_shape(shape,e.x,e.y+130,11,e.angle) end
				if e.x>123 then draw_shape(shape,e.x-130,e.y,11,e.angle) end
				if e.y>123 then draw_shape(shape,e.x,e.y-130,11,e.angle) end
			end
		end
	end

end

function enemies:add(x,y,size,spd_x,spd_y,yeanling) -- size=1(big)~3(small),4(ufo)
	local sx,sy,sr=spd_x,spd_y,0
	if size!=4 then
		if(sx==nil) sx=(0.2+rnd(0.4))*(rndi(1)-0.5)
		if(sy==nil) sy=(0.2+rnd(0.4))*(rndi(1)-0.5)
		sr=(0.5+rnd(1))*(rndi(1)-0.5)*0.01
	end
	local e={
		is_yeanling=yeanling,
		x=x,
		y=y,
		angle=rnd(),
		spd_x=sx,
		spd_y=sy,
		spd_r=sr,
		size=size,
		count=0,
	}
	add(self.list,e)
end

function enemies:kill_all()
	for e in all(self.list) do
		add_break_eff(e.x,e.y,shape_ast2,3,60)
	end
	sfx(3,3)
	self.list={}
end

function enemies:kill_center(r)
	local cx,cy=64,64
	for e in all(self.list) do
		if abs(cx-e.x)<=r and abs(cy-e.y)<=r and get_dist(cx,cy,e.x,e.y)<=r then
			del(self.list,e)
			add_break_eff(e.x,e.y,shape_ast2)
			sfx(3,3)
		end
	end
end



-- <title> --------------------

title=class(sprite)
function title:init()
	self.c=11
	self.tx=10
	self.ty=28
	self:show(true)
end
function title:_draw()
	local x,y=self.tx,self.ty
	if gg.is_title then
		draw_shape(s_title,x,y,self.c,0,true)
		draw_shape(s_demake,x+15,y+20,self.c,0,true)
		draw_shape(s_2022,x+30,y+40,self.c,0,true)
		?get_wave_str("press 🅾️❎ to play"),28,92,self.c

		?"by 🐱seimon",1,120,self.c
		printa("v"..ver,128,120,self.c,1)

		if gg.key_wait>0 then
			gg.key_wait-=1
		elseif btn(4) or btn(5) then
			sfx(6,3)
			add_break_eff(x,y,s_title,3,60)
			add_break_eff(x+15,y+20,s_demake,3,60)
			add_break_eff(x+30,y+40,s_2022,3,60)
			gg.is_title=false
			_ship:reset()
			_ship:show(true)
			_enemies:show(true)
		end
	elseif gg.is_gameover then
		draw_shape(s_game,8,y+12,self.c,0,true)
		draw_shape(s_over,67,y+12,self.c,0,true)
		printa("your score "..get_score_str(),63,70,self.c,0.5)
		?get_wave_str("press 🅾️❎ to coutinue"),18,80,self.c
		_ship:show(false)
		_enemies:show(false)

		if gg.key_wait>0 then
			gg.key_wait-=1
		elseif btn(4) or btn(5) then
			sfx(3,3)
			add_break_eff(8,y+12,s_game,3,60)
			add_break_eff(67,y+12,s_over,3,60)
			gg_reset()
		end
	end
end




-- <etc. functions> --------------------

function get_wave_str(str)
	local str2=""
	for i=1,#str do
		if i==flr(f%60/3) then
			str2=str2.."\|f"..sub(str,i,_).."\|h"
		elseif i==flr((f+6)%60/3) then
				str2=str2.."\|h"..sub(str,i,_).."\|f"
		else
			str2=str2..sub(str,i,_)
		end
	end
	return str2
end

function score_up(size)

	if size==4 then gg.score1+=20
	elseif size==3 then gg.score1+=10
	elseif size==2 then gg.score1+=5
	elseif size==1 then gg.score1+=2
	end

	if gg.score1>=10000 then
		gg.score2=min(gg.score2+1,10000)
		gg.score1-=10000
	end

	-- 5만점마다 보너스
	if gg.score1\5000+gg.score2*2>gg.bonus_earned then
		gg.ships=min(gg.ships+1,8)
		gg.bonus_earned+=1
		-- todo: 보너스 효과
	end

end

function value_loop(v,min,max)
  if v<min then v=(v-min)%(max-min)+min
  elseif v>max then v=v%max+min end
  return v
end

function coord_loop(a)
	local x,y=a.x,a.y
	x=x>131 and x-131 or x<-4 and x+131 or x
	y=y>131 and y-131 or y<-4 and y+131 or y
	a.x=x a.y=y
end

function rotate(x,y,r)
	if(not r or r==0) return {x=x,y=y}
	local cosv=cos(r)
	local sinv=sin(r)
	local p={}
	p.x=cosv*x-sinv*y
	p.y=sinv*x+cosv*y	
	return p
end

function draw_shape(arr,x,y,c,r,with_wave)
	local p1=rotate(arr[1],arr[2],r)
	for i=3,#arr-1,2 do
		if arr[i]=="x" then
			p1={x="x",y="x"}
		else
			local p2=rotate(arr[i],arr[i+1],r)
			if p1.x!="x" then
				if with_wave then
					local dy1=sin((p1.x+p1.y-f)%60/60)*2
					local dy2=sin((p2.x+p2.y-f)%60/60)*2
					line(p1.x+x,p1.y+y+dy1,p2.x+x,p2.y+y+dy2,c)
				else
					line(p1.x+x,p1.y+y,p2.x+x,p2.y+y,c)
				end
			end
			p1=p2
		end
	end
end

function get_dist(x1,y1,x2,y2)
	return sqrt((x2-x1)^2+(y2-y1)^2)
end

function add_debugline_eff(x1,y1,x2,y2)
	add(_space.particles,
		{
			type="debug_line",
			x1=x1,y1=y1,x2=x2,y2=y2,age=0
		})
end
function add_circle_eff(x,y,r_from,r_to,timer)
	add(_space.particles,
		{
			type="circle",
			x=x,
			y=y,
			r1=r_from,
			r2=r_to,
			age=0,
			age_max=timer
		})
end
function add_explosion_eff(x,y,spd_x,spd_y,power,count)
	local c=count or 12
	local p=power or 1
	for i=1,c do
		local sx=cos(i/c+rnd()*0.1)*p
		local sy=sin(i/c+rnd()*0.1)*p
		-- if is_bomb then sx*=1.6 sy*=1.6 end
		--[[ add(_space.particles,
		{
			type="explosion",
			x=x+rnd(3)-1.5,
			y=y+rnd(3)-1.5,
			sx=sx*(0.6+rnd()*1.4)+spd_x*0.7,
			sy=sy*(0.6+rnd()*1.4)+spd_y*0.7,
			size=1,
			age=1+rndi(10)
		}) ]]
		add(_space.particles,
		{
			type="explosion_dust",
			x=x+rnd(2)-1,
			y=y+rnd(2)-1,
			sx=sx*(0.2+rnd(2))+spd_x*p*0.7,
			sy=sy*(0.2+rnd(2))+spd_y*p*0.7,
			age=1+rndi(8)
		})
	end
end
function add_hit_eff(x,y,angle)
	for i=1,8 do
		local a=angle+round(i/8)*0.6-0.3
		local sx=cos(a)
		local sy=sin(a)
		add(_space.particles,
		{
			type="hit",
			x=x+rnd(4)-2,
			y=y+rnd(4)-2,
			sx=sx*(0.7+rnd()*2),
			sy=sy*(0.7+rnd()*2),
			age=1+rndi(5)
		})
	end
end
function add_break_eff(x0,y0,arr,pow,age)
	local pow=pow or 1.5
	local age=age or 10
	local p1={x=arr[1],y=arr[2]}
	for i=3,#arr-1,2 do
		if arr[i]=="x" then
			p1={x="x",y="x"}
		else
			local p2={x=arr[i],y=arr[i+1]}
			if p1.x!="x" then
				local x1,y1,x2,y2=p1.x,p1.y,p2.x,p2.y
				local dx,dy=(x2-x1)/2,(y2-y1)/2
				local v={
					type="line",
					x=x0+x1+dx,y=y0+y1+dy,
					x1=-dx,y1=-dy,
					x2=x2-x1-dx,y2=y2-y1-dy,
					sx=(rnd()-0.5)*pow,sy=(rnd()-0.5)*pow,
					c=11,
					r=(0.1+rnd())*0.02*(rndi(1)-0.5)*pow,
					age=0,age_max=age+rndi(age)
				}
				add(_space.particles,v)
			end
			p1=p2
		end
	end
end

function print_score(len,x,y)
	local t0,t1="",get_score_str()
	for i=1,len-#t1 do t0=t0.."_" end
	printa(t0,x,y,11,0)
	printa(t1,x+len*4,y,11,1)
end
function get_score_str()
	-- 소숫점 덧셈 버그 때문에 정수 2개 사용(0.1+0.1=0.199같은 버그)
	local t=""
	local n1,n2=gg.score1,gg.score2
	if n2>=1000 then t="99999999"
	else
		local t1,t2=tostr(n1),tostr(n2)
		t=n1<=0 and "0" or t1.."0"
		if n2>0 then
			while #t<5 do t="0"..t end
			t=t2..t
		end
	end
	return t
end


-- <constants> --------------------



--------------------------------------------------
f=0 -- every frame +1
stage=sprite.new() -- scene graph top level object

gg={}
function gg_reset()
	gg={
		key_wait=30,
		is_title=true,
		is_gameover=false,
		score1=0,
		score2=0,
		ships=3,
		bonus_earned=0,
		ufo_born=0,
	}	
end

function _init()
	gg_reset()
	--music(13,2000,2)
	_space=space.new()
	_ship=ship.new()
	_enemies=enemies.new()
	_title=title.new()
	_space_f=space.new(true)
	stage:add_child(_space)
	stage:add_child(_ship)
	stage:add_child(_enemies)
	stage:add_child(_title)
	stage:add_child(_space_f)
end
function _update60()
	f+=1
	stage:emit_update()
end
function _draw()
	cls(0)
	stage:render(0,0)

	-- ui
	if not (gg.is_title or gg.is_gameover) then
		fillp(0b1010010110100101.1) rectfill(0,0,127,6,0) fillp()
		-- for i=0,127 do for j=0,6 do pset(i,j,pget(i,j)==0 and 0 or 1) end end -- 좀 무거운 방식이라 개선 필요
		print_score(8,50,1)
		for i=0,gg.ships-1 do
			spr(13,1+i*6,1)
		end
	end

	-- 개발용
	if dev==1 then
		print_log()
		print_system_info()
	end
end
