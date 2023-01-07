dev=0
ver="0.1" -- 2023/01/06
sw=480
sh=270

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

-- <utilities> --------------------
function round(n) return flr(n+.5) end
function swap(v) if v==0 then return 1 else return 0 end end -- 1 0 swap
function clamp(a,min_v,max_v) return min(max(a,min_v),max_v) end
function rndf(lo,hi) return lo+rnd()*(hi-lo) end -- random real number between lo and hi
function rndi(n) return flr(rnd(n)) end -- random int
function printa(t,x,y,c,align,shadow) -- 0.5 center, 1 right align
	x-=align*4*#(tostr(t))
	if (shadow) ?t,x+1,y+1,0
	?t,x,y,c
end

--[[ 
_b0=btn _bm=0
function record() _bm=1 _bp=1 _bt=0 _bd="" end
function playback() _bm=2 _bp=1 _bt=0 end
function btn(p)
  local b=_b0()
  if _bm==1 then -- record
    if b!=_bl then
      if _bd>"" then _bd=_bd.._bt.."," else _bd="" _bt=0 _bp=1 end
      _bl=b _bd=_bd..b.."," _bt=0
    else _bt+=1 end
    if _b0()==4096 then -- tab to stop recording
      printh("btnpb={"..sub(_bd,1,#_bd-1).."}\n","@clip")
      stop()
    end
    return _b0(p)
  elseif _bm==2 then -- playback
		if _b0(4) or _b0(5) then stop_playback() end -- z,x key to stop playback
    if _bt>0 then _bt-=1 
    else
      _bs=btnpb[_bp]
      _bt=btnpb[_bp+1]
      _bp+=2
      if _bt==nil then
				_bm=0
				stop_playback()
			end
    end
    if p==nil then return _bs
    elseif band(_bs,2^p)>0 then return true
    else return false end
  else
    return _b0(p)
  end
end
]]










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
-- s_ufo=str_to_arr("-5,-1,5,-1,3,-4,-3,-4,-5,-1,-5,1,-3,4,3,4,5,1,-5,1,x,x,-3,-1,-3,1,x,x,-1,-1,-1,1,x,x,1,-1,1,1,x,x,3,-1,3,1,x,x,5,-1,5,1")
s_ufo=str_to_arr("-5,-1,5,-1,2,-4,-2,-4,-5,-1,-5,1,-2,4,2,4,5,1,-5,1,x,x,-3,-1,-3,1,x,x,-1,-1,-1,1,x,x,1,-1,1,1,x,x,3,-1,3,1,x,x,5,-1,5,1")
s_ship=str_to_arr("4,0,-4,4,-2,0,-4,-4,4,0")
s_ship2=str_to_arr("0,-4,4,4,0,2,-4,4,0,-4") -- remain ships
s_shield=str_to_arr("0,-3,-2,-2,-3,0,-2,2,0,3,2,2,3,0,2,-2,0,-3",3)
s_ast10=str_to_arr("4,0,2,-1,2,-3,-1,-4,-2,-2,-4,0,-2,1,-3,2,-2,4,0,3,2,4,4,0",2.3)
s_ast11=str_to_arr("0,-4,-4,-2,-3,0,-3,3,0,4,1,2,3,2,4,-2,0,-4",2.3)
s_ast20=str_to_arr("4,0,2,4,0,3,-2,4,-4,2,-4,-2,-2,-4,0,-2,3,-3,4,0",1.5)
s_ast21=str_to_arr("0,-4,-2,-2,-4,-2,-3,1,-3,3,1,4,2,1,4,-1,0,-4",1.6)
s_ast30=str_to_arr("4,2,2,4,-4,0,-2,-4,3,-3,4,2",1)
s_ast31=str_to_arr("-4,0,-2,-4,2,-4,4,-2,4,2,0,4,-4,0",0.95)
s_title_str="0,6,3,0,6,6,10,6,10,4,6,2,6,0,10,0,14,0,x,x,12,0,12,6,x,x,1,4,5,4" -- AST
s_title_str=s_title_str..",x,x,19,0,15,0,15,6,19,6,x,x,15,3,18,3" -- E
s_title_str=s_title_str..",x,x,20,6,20,0,24,0,24,3,21,3,24,6,x,x,25,6,28,6,29,4,29,0,26,0,25,2,25,6" -- RO
s_title_str=s_title_str..",x,x,30,0,32,0,x,x,31,0,31,6,x,x,30,6,32,6" -- I
s_title_str=s_title_str..",x,x,33,6,36,6,37,4,37,2,36,0,33,0,33,6,x,x,38,6,42,6,42,4,38,2,38,0,42,0" -- DS
-- s_title=str_to_arr(s_title_str,2.5)
-- s_demake=str_to_arr("0,0,0,6,3,6,4,4,4,2,3z,0,0,0,x,x,9,0,5,0,5,6,10,6,10,0,13,6,16,0,16,6,19,0,22,6,22,0,x,x,31,0,27,0,27,6,31,6,x,x,5,3,8,3,x,x,17,4,21,4,x,x,26,0,22,3,26,6,x,x,27,3,30,3",2.5)
-- s_2022=str_to_arr("0,0,4,0,4,2,0,4,0,6,4,6,x,x,6,0,5,2,5,6,8,6,9,4,9,0,6,0,x,x,6,5,8,1,x,x,10,0,14,0,14,2,10,4,10,6,14,6,x,x,15,0,19,0,19,2,15,4,15,6,19,6",2.5)
s_title=str_to_arr(s_title_str,4)
s_demake=str_to_arr("0,0,0,6,3,6,4,4,4,2,3,0,0,0,x,x,9,0,5,0,5,6,10,6,10,0,13,6,16,0,16,6,19,0,22,6,22,0,x,x,31,0,27,0,27,6,31,6,x,x,5,3,8,3,x,x,17,4,21,4,x,x,26,0,22,3,26,6,x,x,27,3,30,3",4)
s_2022=str_to_arr("0,0,4,0,4,2,0,4,0,6,4,6,x,x,6,0,5,2,5,6,8,6,9,4,9,0,6,0,x,x,6,5,8,1,x,x,10,0,14,0,14,2,10,4,10,6,14,6,x,x,15,0,19,0,19,2,15,4,15,6,19,6",4)
s_2023=str_to_arr("0,0,4,0,4,2,0,4,0,6,4,6,x,x,6,0,5,2,5,6,8,6,9,4,9,0,6,0,x,x,6,5,8,1,x,x,10,0,14,0,14,2,10,4,10,6,14,6,x,x,15,0,19,0,19,2,17,3,19,4,19,6,15,6",4)
-- s_game=str_to_arr("4,0,1,0,0,2,0,6,4,6,4,3,2,3,x,x,4,6,7,0,10,6,10,0,13,6,16,0,16,6,x,x,5,4,9,4,x,x,21,0,17,0,17,6,21,6,x,x,17,3,20,3",2.5)
-- s_over=str_to_arr("4,0,4,4,3,6,0,6,0,2,1,0,4,0,x,x,5,0,8,6,11,0,x,x,16,0,12,0,12,6,16,6,x,x,12,3,15,3,x,x,17,6,17,0,21,0,21,3,18,3,21,6",2.5)
s_game=str_to_arr("4,0,1,0,0,2,0,6,4,6,4,3,2,3,x,x,4,6,7,0,10,6,10,0,13,6,16,0,16,6,x,x,5,4,9,4,x,x,21,0,17,0,17,6,21,6,x,x,17,3,20,3",4)
s_over=str_to_arr("4,0,4,4,3,6,0,6,0,2,1,0,4,0,x,x,5,0,8,6,11,0,x,x,16,0,12,0,12,6,16,6,x,x,12,3,15,3,x,x,17,6,17,0,21,0,21,3,18,3,21,6",4)
s_circle={}
for i=0,36 do
	local r=i/24
	local x,y=cos(r)*80,sin(r)*80
	add(s_circle,x)
	add(s_circle,y)
end
s_num={}
s_num["_"]=str_to_arr("0,4,2,4",3)
s_num["0"]=str_to_arr("0,0,2,0,2,4,0,4,0,0,x,x,1,1.5,1,2.5",3) --0
s_num["1"]=str_to_arr("0,1,1,0,1,4,x,x,0,4,2,4",3) -- 1
s_num["2"]=str_to_arr("0,1,0,0,2,0,2,1,0,3,0,4,2,4",3) -- 2
s_num["3"]=str_to_arr("0,0,2,0,1,2,x,x,0,2,2,2,2,4,0,4",3)
s_num["4"]=str_to_arr("1,0,0,3,2,3,x,x,2,0,2,4",3)
s_num["5"]=str_to_arr("2,0,0,0,0,1,2,2,2,4,0,4,0,3",3)
s_num["6"]=str_to_arr("2,1,2,0,0,0,0,4,2,4,2,2,0,2",3)
s_num["7"]=str_to_arr("0,1,0,0,2,0,1,4",3)
s_num["8"]=str_to_arr("0,0,2,0,2,4,0,4,0,0,x,x,0,2,2,2",3)
s_num["9"]=str_to_arr("2,2,0,2,0,0,2,0,2,4,0,4,0,3",3)
s_shield_o=str_to_arr("0,0,6,0,6,5,3,7,0,5,0,0,x,x,3,0,3,7",1)
s_shield_x=str_to_arr("0,0,6,0,6,5,3,7,0,5,0,0,x,x,3,0,3,7,x,x,-2,6,8,-1",1)
-- s_shield_x=str_to_arr("0,4,0,0,6,0,x,x,6,2,6,5,3,7,1,6,x,x,3,0,3,2,x,x,3,4,3,7,x,x,-1,6,7,0",1)




-- <space> --------------------
space=class(sprite)
function space:init()
	self.spd_x=0.3
	self.spd_y=0
	self.stars={}
	self.particles={}

	local function make_star(i,max,base_spd)
		return {
			-- x=rnd(127),
			-- y=rnd(127),
			x=rnd(sw),
			y=rnd(sh),
			spd=base_spd+i/max*base_spd,
			size=1+rnd(1)
		}
	end
	for i=1,200 do add(self.stars,make_star(i,200,1)) end

	self:show(true)
	self:on("update",self.on_update)
end

ptcl_size_explosion="56776655443321111000"

function space:_draw()
	-- stars
	for v in all(self.stars) do
		local x=v.x-self.spd_x*v.spd
		local y=v.y+self.spd_y*v.spd
		v.x=x>sw+1 and x-sw-1 or x<-2 and x+sw+1 or x
		v.y=y>sh+1 and y-sh-1 or y<-2 and y+sh+1 or y
		if v.size>1.9 then circfill(v.x,v.y,1,1)
		else pset(v.x,v.y,1) end
	end

	-- particles
	for i,v in pairs(self.particles) do
		if v.type=="thrust" then
			pset(v.x,v.y,cc)
			v.x+=v.sx+rnd(4)-2
			v.y+=v.sy+rnd(4)-2
			v.sx*=0.93
			v.sy*=0.93
			if(v.age>6) del(self.particles,v)

	elseif v.type=="bullet" or v.type=="bullet_ufo" then
			v.x+=v.sx
			v.y+=v.sy
			coord_loop(v)
			if v.type=="bullet_ufo" then circ(v.x,v.y,1,cc) else pset(v.x,v.y,cc) end
			if(v.age>v.age_max) del(self.particles,v)

			-- 적과 충돌 처리
			local killed={}
			for e in all(_enemies.list) do
				local dist=(e.size==4) and 7 or (e.size==1) and 9 or (e.size==2) and 7 or 5
				if abs(v.x-e.x)<=dist and abs(v.y-e.y)<=dist and get_dist(v.x,v.y,e.x,e.y)<=dist then
					score_up(e.size)
					if(e.size<3) add(killed,{x=e.x,y=e.y,size=e.size})
					add_break_eff(e.x,e.y,e.shape)
					add_explosion_eff(e.x,e.y,v.sx,v.sy)
					if(e.size==4) add_break_eff(e.x,e.y,s_ufo,2,40) add_explosion_eff(e.x,e.y,v.sx,v.sy,1.6,30)
					del(self.particles,v)
					del(_enemies.list,e)
					-- sfx(3,3)
				end
			end
			for e in all(killed) do
				_enemies:add(e.x+1,e.y+1,e.size+1)
				_enemies:add(e.x-1,e.y-1,e.size+1)
			end

			if v.type=="bullet_ufo" then
				-- ship과 충돌 처리
				local dist=4+(_ship.use_shield and 6 or 0)
				local x,y=_ship.x,_ship.y
				if abs(v.x-x)<=dist and abs(v.y-y)<=dist and get_dist(v.x,v.y,x,y)<=dist then
					if _ship.use_shield then
						_ship.shield_timer-=50
						shake(30,0.3)
						add_explosion_eff(v.x,v.y,v.sx,v.sy)
						-- sfx(3,3)
					else _ship:kill() end
					del(self.particles,v)
				end
			end

		elseif v.type=="explosion" then
			circ(v.x,v.y,ptcl_size_explosion[v.age]*v.size,cc)
			v.x+=v.sx+rnd(1)-0.5
			v.y+=v.sy+rnd(1)-0.5
			v.sx*=0.9
			v.sy*=0.9
			if(v.age>18) del(self.particles,v)

		elseif v.type=="explosion_dust" then
			pset(v.x,v.y,cc)
			v.x+=v.sx
			v.y+=v.sy
			v.sx*=0.9
			v.sy*=0.9
			if(v.age>28) del(self.particles,v)

		elseif v.type=="hit" then
			pset(v.x,v.y,cc)
			v.x+=v.sx
			v.y+=v.sy
			v.sx*=0.94
			v.sy*=0.94
			if(v.age>12) del(self.particles,v)

		elseif v.type=="line" then
			line(v.x+v.x1,v.y+v.y1,v.x+v.x2,v.y+v.y2,cc)
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
			circ(v.x,v.y,r,cc)
			if(v.age>v.age_max) del(self.particles,v)

		elseif v.type=="bonus" then
			local x=min(2,-17-sin((120-v.age)/240)*20)
			?"BONUS!",x,13,cc
			if(v.age>120) del(self.particles,v)

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
	self.x=sw/2
	self.y=sh/2
	self.spd=0
	self.spd_x=0
	self.spd_y=0
	self.spd_max=1.3
	self.angle=0
	self.angle_acc=0
	self.angle_acc_power=0.0009
	self.thrust=0
	self.thrust_acc=0
	self.thrust_power=0.0008
	self.thrust_max=1.0
	self.tail={x=0,y=0}
	self.head={x=0,y=0}
	self.fire_spd=2.0
	self.fire_intv=0
	self.fire_intv_full=8
	
	self.use_shield=false
	self.shield_enable=true
	self.shield_timer=200
	self.shield_timer_max=200
	
	self.is_killed=false
	
	-- self:on("update",self.on_update) -- stage:emit_update()가 동작 안해서 꺼놨음
	self.__on_killed=false
	self.__show=true
end

function ship:_draw()

	self:on_update()
	if(self.__on_killed) self:on_killed()

	if(not self.__show) return

	local x,y=self.x,self.y
	self:draw_ship(x,y)
	local x0=cos(self.angle)
	local y0=sin(self.angle)
	self.tail.x=x-x0*6
	self.tail.y=y-y0*6	
	self.head.x=x+x0*8
	self.head.y=y+y0*8

	-- 변두리에 있을 때 맞은편에도 그림
	if x<4 then self:draw_ship(x+sw+2,y) end
	if y<4 then self:draw_ship(x,y+sh+2) end
	if x>123 then self:draw_ship(x-sw-2,y) end
	if y>123 then self:draw_ship(x,y-sh-2) end
end

function ship:draw_ship(x,y)
	draw_shape(s_ship,x,y,cc,self.angle)
	if self.use_shield then
		local r=self.shield_timer/self.shield_timer_max
		draw_shape(s_shield,x,y,cc,-f%30/30,false,r)
	end
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

		if(dev==1) score_up(4)

		-- sfx(23,-1)
		self.fire_intv=self.fire_intv_full
		local a=self.angle+rnd()*0.02-0.01
		local fire_spd_x=cos(a)*self.fire_spd+self.spd_x*1.4
		local fire_spd_y=sin(a)*self.fire_spd+self.spd_y*1.4
		add(_space.particles,
		{
			type="bullet",
			x=self.head.x,
			y=self.head.y,
			sx=fire_spd_x,
			sy=fire_spd_y,
			age_max=80,
			age=1
		})
	end

	-- shield
	if(self.shield_timer<=0) self.shield_enable=false self.shield_timer=max(self.shield_timer,0)
	if btn(5) and self.shield_timer>0 and self.shield_enable then
		self.use_shield=true
		self.shield_timer-=1
	else
		self.use_shield=false
		if self.shield_enable then
			if(self.shield_timer<self.shield_timer_max) self.shield_timer+=0.5
		else
			self.shield_timer+=0.3
			if(self.shield_timer>=self.shield_timer_max) self.shield_enable=true
		end
	end

	-- add effect
	if self.thrust_acc>0.001 then
		-- sfx(4,2)
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
		-- sfx(5,2)
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
		-- sfx(-1,2)
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
		local dist=(e.size==1) and 11 or (e.size==2) and 9 or 7
		if(self.use_shield) dist+=4
		if abs(e.x-x)<=dist and abs(e.y-y)<=dist and get_dist(e.x,e.y,x,y)<=dist then	
			if self.use_shield then
				self.shield_timer-=50
				shake(30,0.3)
				-- 충돌 방향만 보고 서로 반대로 밀기
				local d=atan2(e.x-x,e.y-y)
				local sx,sy=cos(d)*0.35,sin(d)*0.35
				e.spd_x=sx
				e.spd_y=sy
				e.x+=sx*2
				e.y+=sy*2
				self.spd_x=-sx
				self.spd_y=-sy
				self.x-=sx*2
				self.y-=sy*2
				-- sfx(2,3)
				add_hit_eff((x+e.x)/2,(y+e.y)/2,d)
			elseif not self.is_killed then
				self:kill()
			end
		end
	end
end

function ship:kill()
	if(self.is_killed) return

	-- sfx(3,3)
	-- sfx(-1,2) -- 분사음 강제로 끔
	local x,y=self.x,self.y
	add_explosion_eff(x,y,self.spd_x,self.spd_y,2,40)
	add_break_eff(x,y,s_ship,1,60)
	add_break_eff(x,y,s_ship,2,60)

	self.is_killed=true
	-- self:show(false)
	self.__show=false
	self.revive_count=150
	
	-- self:on("update",self.on_killed)
	self.__on_killed=true

	shake()
end

function ship:on_killed()
	self.revive_count-=1
	if(self.revive_count==60 and gg.ships>=1) add_circle_eff(sw/2,sh/2,4,80,60)
	if self.revive_count<=0 then
		gg.ships-=1
		if gg.ships>=0 then
			add_break_eff(sw/2,sh/2,s_circle,0.8,20)
			self:revive()
		else
			_enemies:kill_all()
			gg.is_gameover=true
			gg.scene_timer=0
			gg.key_wait=30
			shake()
		end
		-- self:remove_handler("update",self.on_killed)
		self.__on_killed=false
	end
end

function ship:reset()
	self.x,self.y=sw/2,sh/2
	self.spd=0
	self.spd_x,self.spd_y=0,0
	self.angle=0
	self.angle_acc=0
	self.thrust=0
	self.thrust_acc=0
	self.is_killed=false
	self.shield_enable=true
	self.shield_timer=self.shield_timer_max
end

function ship:revive()
	_enemies:kill_center(85)
	self:reset()
	-- self:show(true)
	self.__show=true
	add_explosion_eff(sw/2,sh/2,0,0,2,40)
end







-- <enemies> --------------------
enemies=class(sprite)
function enemies:init()
	self.list={}
end

function enemies:group_update() -- 소행성 수를 일정하게 맞춰준다
	if gg.is_gameover then return end
	-- srand(f%101)

	local c1,c2,c3,c4=0,0,0,0
	for e in all(self.list) do
		if(e.size==1) c1+=1
		if(e.size==4) c4+=1
	end

	local df=min(40,4+gg.score1\2000+gg.score2*5) -- 난이도 2만점마다 증가(큰 소행성이 리필되는 수 4~40)
	if c1<df and #self.list<8+df then
		local r=rnd()
		local x=cos(r)*sw
		local y=sin(r)*sh
		-- self:add(sw/2+x,sh/2+y,1,-x*0.002,-y*0.002,true)
		self:add(sw/2+x,sh/2+y,1,-x*0.001,-y*0.001,true)
	end

	if c4<1 and gg.score1\2000+gg.score2*5>gg.ufo_born then -- 20000점마다 UFO 출현
		-- self:add(-10,sh/2+rndi(80)-40,4,0.2,0,true)
		self:add(-10,sh/2+rndi(80)-40,4,0.4,0,true)
		gg.ufo_born+=1
	end

end

function enemies:_draw()
	
	if(f%67==0) self:group_update() -- 주기적으로 소행성 수량 조절

	for i,e in pairs(self.list) do
		e.x+=e.spd_x
		e.y+=e.spd_y
		e.angle=value_loop(e.angle+e.spd_r,0,1)
		
		if e.is_yeanling then
			if(e.x>5 and e.x<sw-6 and e.y>5 and e.y<sh-6) e.is_yeanling=false
		else
			coord_loop(e)
		end

		if e.size==4 then
			-- pal({[11]=cc}) spr(0+e.type*2,e.x-5,e.y-4,2,2) pal() -- spr() Not work on Picotron
			-- circ(e.x,e.y,3,cc-3) circ(e.x,e.y,5,cc-3)
			draw_shape(s_ufo,e.x,e.y,cc)

			pset(e.x-4+(round(e.count/9)%5)*2,e.y,cc)
			if(e.type==1 and f%240==0) e.spd_y*=-1 -- UFO 타입1은 지그재그 운행
			e.count+=1
			-- if e.count>=100 and not _ship.is_killed then
			-- if e.count>=20 and not _ship.is_killed then
			-- ufo가 새로 나올 때마다 총알 인터벌이 점점 짧아짐
			if e.count>=max(20,100-gg.ufo_born*5) and not _ship.is_killed then
				-- sfx(24,1)
				e.count=0
				-- sfx(23,-1)
				local angle=atan2(_ship.x-e.x+rnd(10)-5,_ship.y-e.y+rnd(10)-5)
				local sx=cos(angle+rnd()*0.03)
				local sy=sin(angle+rnd()*0.03)
				add(_space.particles,
				{
					type="bullet_ufo",
					x=e.x+sx*7,
					y=e.y+sy*7,
					sx=sx*0.6*min(3,1+gg.ufo_born/5),
					sy=sy*0.6*min(3,1+gg.ufo_born/5),
					age_max=300,
					age=1
				})
			end

			-- UFO는 화면 밖으로 나가면 사라짐
			-- if(e.x>130) del(self.list,e)
			if(e.x>sw+2) del(self.list,e)

		else
			-- 크기 테스트용
			-- local r=(e.size==4) and 7 or (e.size==1) and 9 or (e.size==2) and 7 or 5
			-- circ(e.x,e.y,r,8)
			
			draw_shape(e.shape,e.x,e.y,cc,e.angle)

			-- 변두리에 있을 때 맞은편에도 그림(생성 초기는 제외)
			if not e.is_yeanling then
				if e.x<4 then draw_shape(e.shape,e.x+sw+2,e.y,cc,e.angle) end
				if e.y<4 then draw_shape(e.shape,e.x,e.y+sh+2,cc,e.angle) end
				if e.x>sw-5 then draw_shape(e.shape,e.x-sw-2,e.y,cc,e.angle) end
				if e.y>sh-5 then draw_shape(e.shape,e.x,e.y-sh-2,cc,e.angle) end
			end
		end
	end

end

function enemies:add(x,y,size,spd_x,spd_y,yeanling) -- size=1(big)~3(small),4(ufo)
	local sx,sy,sr,sp=spd_x,spd_y,0,s_ufo
	if size<4 then
		-- if(sx==nil) sx=(0.1+rnd(0.3))*(rndi(2)-0.5)
		-- if(sy==nil) sy=(0.1+rnd(0.3))*(rndi(2)-0.5)
		if(sx==nil) sx=(0.2+rnd(0.3))*(rndi(2)-0.5)
		if(sy==nil) sy=(0.2+rnd(0.3))*(rndi(2)-0.5)
		sr=(0.5+rnd(1))*(rndi(2)-0.5)*0.01
		sp=(size==1) and s_ast10 or (size==2) and s_ast20 or s_ast30
		-- if(sx>0) sp=(size==1) and s_ast11 or (size==2) and s_ast21 or s_ast31
		if(#self.list%2<1) sp=(size==1) and s_ast11 or (size==2) and s_ast21 or s_ast31
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
		shape=sp,
		count=0,
	}
	if size==4 then
		e.type=gg.ufo_born%3
		if(e.type>0) e.spd_y=0.3
	end
	add(self.list,e)
end

function enemies:kill_all()
	for e in all(self.list) do
		add_break_eff(e.x,e.y,s_ast20,3,60)
	end
	-- sfx(3,3)
	self.list={}
end

function enemies:kill_center(r)
	local cx,cy=sw/2,sh/2
	for e in all(self.list) do
		if abs(cx-e.x)<=r and abs(cy-e.y)<=r and get_dist(cx,cy,e.x,e.y)<=r then
			del(self.list,e)
			add_break_eff(e.x,e.y,s_ast20)
			-- sfx(3,3)
		end
	end
end





-- <title> --------------------

title=class(sprite)
function title:init()
	-- self.tx=10
	-- self.ty=28
	-- self.tx=sw/2-54
	-- self.ty=sh/2-38
	self.tx=sw/2-84
	self.ty=sh/2-50
	self:show(true)
end
function title:_draw()
	local x,y=self.tx,self.ty
	if gg.is_title then
		-- rect(sw/2-90,sh/2-60,sw/2+90,sh/2+60,cc+1)
		-- rect(sw/2-80,sh/2-50,sw/2+80,sh/2+50,cc+2)
		-- rect(sw/2-70,sh/2-40,sw/2+70,sh/2+40,cc+3)
		-- rect(sw/2-60,sh/2-30,sw/2+60,sh/2+30,cc+4)
		-- rect(sw/2-50,sh/2-20,sw/2+50,sh/2+20,cc+5)
		draw_shape(s_title,x,y,cc,0,true)
		draw_shape(s_demake,x+22,y+30,cc,0,true)
		draw_shape(s_2023,x+45,y+60,cc,0,true)
		
		-- ?get_wave_str("press 🅾️❎ to play"),28,92,cc
		-- ?get_wave_str("press any key to play"),28,92,cc
		?"Press any key to PLAY",sw/2-52,sh/2+48,f%60<30 and cc or 0

		-- ?"v"..ver,2,sh-9,cc
		-- circ(sw/2,sh-9,50,cc+1)
		-- circ(sw/2,sh-9,70,cc+1)
		-- circ(sw/2,sh-9,90,cc+1)
		?"(C)1979 ATARI INC, Demaked by @mooon",sw/2-90,sh-11,cc

		if gg.key_wait>0 then
			gg.key_wait-=1
		elseif btn(4) or btn(5) then
			-- sfx(6,3)
			add_break_eff(x,y,s_title,3.5,80)
			add_break_eff(x+22,y+30,s_demake,3.5,80)
			add_break_eff(x+45,y+60,s_2023,3.5,80)
			gg.is_title=false
			-- set_menu()
			_ship:reset()
			_ship:show(true)
			_ship.__show=true
			_enemies:show(true)
			
			-- 데모 플레이 반복할 때 같은 상황이 연출되게끔 여기서 리셋
			f=0
			-- srand(0)
		end
	elseif gg.is_gameover then
		-- draw_shape(s_game,sw/2-92,y+28,cc,0,true)
		-- draw_shape(s_over,sw/2+8,y+28,cc,0,true)
		draw_shape(s_game,sw/2-92,y,cc,0,true)
		draw_shape(s_over,sw/2+8,y,cc,0,true)
		?"YOUR SCORE",sw/2-24,y+40,cc
		print_score(8,sw/2,sh/2+4)
		-- ?get_wave_str("press 🅾️❎ to coutinue"),18,80,cc
		-- ?get_wave_str("press any key to coutinue"),18,80,cc
		?"Press any key to continue",sw/2-62,sh/2+34,f%60<30 and cc or 0
		_ship:show(false)
		_ship.__show=false
		_enemies:show(false)

		if gg.key_wait>0 then
			gg.key_wait-=1
		elseif btn(4) or btn(5) then
			-- sfx(3,3)
			add_break_eff(sw/2-92,y,s_game,3,60)
			add_break_eff(sw/2+8,y,s_over,3,60)
			gg_reset()
		end
	end
end







-- <etc. functions> --------------------

function get_wave_str(str)
	local str2=""
	for i=1,#str do
		if i==flr(f%60/3) then
			str2=str2.."\|f"..str[i].."\|h"
		elseif i==flr((f+6)%60/3) then
				str2=str2.."\|h"..str[i].."\|f"
		else
			str2=str2..str[i]
		end
	end
	return str2
end

function score_up(size)

	-- 원래는 소행성 크기별로 20,50,100점인데 좀 뻥튀기 함
	if size==4 then gg.score1+=300
	elseif size==3 then gg.score1+=50
	elseif size==2 then gg.score1+=20
	elseif size==1 then gg.score1+=8
	end

	if gg.score1>=10000 then
		gg.score2=min(gg.score2+1,10000)
		gg.score1-=10000
	end

	-- 5만점마다 보너스
	if gg.score1\5000+gg.score2*2>gg.bonus_earned then
		gg.ships=min(gg.ships+1,8)
		gg.bonus_earned+=1
		-- sfx(25,1)
		add(_space.particles,{type="bonus",age=0})
	end

end

function value_loop(v,min,max)
  if v<min then v=(v-min)%(max-min)+min
  elseif v>max then v=v%max+min end
  return v
end

function coord_loop(a)
	local x,y=a.x,a.y
	-- x=x>131 and x-131 or x<-4 and x+131 or x
	-- y=y>131 and y-131 or y<-4 and y+131 or y
	x=x>sw+3 and x-sw-3 or x<-4 and x+sw+3 or x
	y=y>sh+3 and y-sh-3 or y<-4 and y+sh+3 or y
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

function draw_shape(arr,x,y,c,angle,with_wave,draw_ratio)
	local p1=rotate(arr[1],arr[2],angle)
	local i2=#arr-1
	if draw_ratio then i2=3+flr(#arr-3)*clamp(draw_ratio,0,1) end
	for i=3,i2,2 do
		if arr[i]=="x" then
			p1={x="x",y="x"}
		else
			local p2=rotate(arr[i],arr[i+1],angle)
			if p1.x!="x" then
				if with_wave then
					-- local dy1=sin((p1.x+p1.y-f)%60/60)*2
					-- local dy2=sin((p2.x+p2.y-f)%60/60)*2
					local dy1=sin((p1.x+p1.y-t()*60)%60/60)*2
					local dy2=sin((p2.x+p2.y-t()*60)%60/60)*2
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
			age=1+rndi(6)
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
					r=(0.1+rnd())*0.02*(rndi(2)-0.5)*pow,
					age=0,age_max=age+rndi(age)
				}
				add(_space.particles,v)
			end
			p1=p2
		end
	end
end

function print_score(len,x,y)
	-- local t0,t1="",get_score_str()
	-- for i=1,len-#t1 do t0=t0.."_" end
	-- printa(t0,x,y,cc,0,true)
	-- printa(t1,x+len*4,y,cc,1,true)

	-- circ(x,y,30,cc-1)
	-- circ(x,y,38,cc-1)
	-- circ(x,y,44,cc-1)
	local function shake_diff()
		return stage.__on_shake and (rnd(12)-6)*shake_t/100 or 0
	end

	local t0,t1="",get_score_str()
	local lx=x-len/2*9-8
	for i=1,len-#t1 do t1="_"..t1 end
	for i=1,#t1 do
		local n=sub(t1,i,i)
		local x2=lx+i*9+shake_diff()
		local y2=y+shake_diff()
		draw_shape(s_num[n],x2,y2,cc,shake_diff()*0.006)
	end

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

function shaking()
	if shake_t>0 then
		local n=0.3+shake_t/10*shake_p
		if(shake_t%2==0) camera(rnd(n)-n/2,rnd(n)-n/2)
		shake_t-=1
	else
		camera(0,0)
		-- stage:remove_handler("update",shaking)
		stage.__on_shake=false
	end
end
function shake(dur,pwr)
	shake_t=dur or 80
	shake_p=pwr or 1
	-- stage:on("update",shaking)
	stage.__on_shake=true
end












--------------------------------------------
cc=11 -- default color 11
gg_reset=function()
	gg={
		key_wait=20,
		is_title=true,
		is_gameover=false,
		score1=0,
		score2=0,
		ships=3,
		bonus_earned=0,
		ufo_born=0,
	}	
end
gg_reset()
function _init()
	f=0 -- every frame +1
	-- srand(0) -- not work on Picotron
	gg_reset()
	stage=sprite.new()
	stage.__on_shake=false

	_space=space.new()
	_ship=ship.new()
	_enemies=enemies.new()
	_title=title.new()
	stage:add_child(_space)
	stage:add_child(_ship)
	stage:add_child(_enemies)
	stage:add_child(_title)
end
function _update()
	f+=1
	-- stage:emit_update()
	if(stage.__on_shake) shaking()

	
end
function _draw()
	cls(0)
	stage:render(0,0)

	-- ui
	if not (gg.is_title or gg.is_gameover) then
		print_score(8,sw/2,3)

		-- pal({[11]=cc}) palt(3,true) palt(0,false)
		-- for i=0,gg.ships-1 do spr(13,1+i*6,1) end
		-- spr(_ship.shield_enable and 11 or f%30<15 and 11 or 12,122,1)
		-- palt()

		-- for i=0,gg.ships-1 do draw_shape(s_ship,7+i*9,6,cc) end
		for i=0,gg.ships-1 do draw_shape(s_ship2,7+i*10,7,cc) end

		if _ship.shield_enable then draw_shape(s_shield_o,sw-10,3,cc)
		elseif f%30<15 then draw_shape(s_shield_x,sw-10,3,cc) end

		-- local w=_ship.shield_timer/_ship.shield_timer_max*26
		local w=_ship.shield_timer/_ship.shield_timer_max*50
		if w>1 then
			-- if(not _ship.shield_enable) fillp(f%30<15 and 0b1111111111111111.1 or 0b0101010101010101.1)
			if(not _ship.shield_enable and f%30<15) for i=0,7 do poke(0x5500+i,i%2==0 and 85 or 170) end
			-- line(121-w,4,121,4,0)
			-- line(120-w,3,120,3,cc)

			-- line(sw-6-w,4,sw-6,4,0)
			line(sw-14-w,6,sw-14,6,cc)
			fillp()
		end
	end
end
