module perfontain.managers.gui.basic;

import
		std.range,
		std.stdio,
		std.algorithm,

		perfontain;

public import
				perfontain.managers.gui.button;


class GUIQuad : GUIElement
{
	this(GUIElement p, Color c)
	{
		super(p);

		_c = c;
	}

	override void draw(Vector2s p) const
	{
		drawQuad(p + pos, size, _c);

		super.draw(p);
	}

private:
	Color _c;
}

class Table : GUIElement
{
	this(GUIElement p, ushort cols)
	{
		super(p);
		_cols = cols;
	}

	void add(GUIElement e)
	{
		e.attach(this);
	}

	void adjust(ushort pad = 0)
	{
		RCArray!GUIElement	cs = childs,
							arr = _cols.iota.map!(_ => new GUIElement(null)).array;

		foreach(i, c; cs)
		{
			c.attach(arr[i % _cols]);
		}

		{
			ushort sy;

			foreach(i, c; arr)
			{
				c.toChildSize;

				if(i)
				{
					c.moveX(arr[i - 1], POS_ABOVE, pad);
				}

				sy = max(sy, c.size.y);
			}

			arr.each!(a => a.size.y = sy);
		}

		foreach(i, c; cs)
		{
			auto r = arr[i % _cols];
			auto e = new GUIElement(this, r.size);

			e.move(r, POS_MIN, 0, this, POS_MIN, cast(uint)i / _cols * (e.size.y + pad));
			c.attach(e);
		}

		toChildSize;
	}

private:
	ushort _cols;
}

class GUIImage : GUIElement
{
	this(GUIElement p, uint id, ubyte mode = 0, MeshHolder h = null)
	{
		super(p);

		_mode = mode;
		_id = cast(ushort)id;

		if(h)
		{
			_holder = h;
		}
		else
		{
			size = sizeFor(_id);

			if(mode & DRAW_ROTATE)
			{
				swap(size.x, size.y);
			}
		}
	}

	override void draw(Vector2s p) const
	{
		drawImage(_holder ? _holder : PE.gui.holder, _id, p + pos, color, Vector2s.init, _mode);
	}

	override void onPress(bool b)
	{
		if(onClick && b)
		{
			onClick();
		}
	}

	auto color = colorWhite;
	void delegate() onClick;
protected:
	RC!MeshHolder _holder;
	ushort _id;
	ubyte _mode;
}

final class CheckBox : GUIImage
{
	this(GUIElement p, bool ch = false)
	{
		super(p, ch ? CHECKBOX_CHECKED : CHECKBOX);

		checked = ch;
		flags.captureFocus = true;
	}

	bool checked;
	void delegate(bool) onChange;
protected:
	override void onPress(bool st)
	{
		if(st)
		{
			checked ^= true;

			if(onChange)
			{
				onChange(checked);
			}

			_id = checked ? CHECKBOX_CHECKED : CHECKBOX;
		}
	}
}

class Underlined : GUIElement
{
	this(GUIElement e)
	{
		super(e);
	}

	void update()
	{
		toChildSize;
		size.y++;
	}

	override void draw(Vector2s p) const
	{
		super.draw(p);

		drawQuad(p + pos + Vector2s(0, size.y - 1), Vector2s(size.x, 1), Color(128, 128, 128, 200));
	}
}

class GUIEditText : GUIElement
{
	this(GUIElement e)
	{
		super(e, Vector2s(0, PE.fonts.base.height), Win.enabled);
	}

	override void draw(Vector2s p) const
	{
		p += pos;

		if(_ob)
		{
			drawImage(_ob, 0, p, colorBlack, Vector2s(_w, size.y));

			p.x += _w;
		}

		if(flags.enabled && flags.hasInput && (PE.tick - _tick) % 1000 < 500)
		{
			drawQuad(p, Vector2s(1, size.y), colorBlack);
		}
	}

	override void onSubmit()
	{
		if(onEnter && onEnter(_text))
		{
			_text = null;
			update;
		}
	}

	override void onKey(uint k, bool st)
	{
		if(flags.enabled && k == SDLK_BACKSPACE && st && _text.length)
		{
			_text.popBack;
			update;
		}
	}

	override void onText(string s)
	{
		if(flags.enabled && (!onChar || onChar(s)))
		{
			_text ~= s;
			update;
		}
	}

	@property value()
	{
		return _text;
	}

	void clear()
	{
		_text = null;
		update;
	}

	bool delegate(string)	onChar,
							onEnter;
protected:
	override void onFocus(bool b)
	{
		if(b)
		{
			input;
			_tick = PE.tick;
		}
	}

	void update()
	{
		_ob = null;

		if(_text.length)
		{
			auto im = PE.fonts.base.render(_text);

			auto x = size.x - 1;
			auto v = max(float(im.w) - x, 0) / im.w;

			_ob = PEobjs.makeHolder(im, v);
			_w = cast(ushort)min(im.w, x);
		}
	}

	string _text;
private:
	RC!MeshHolder _ob;

	ushort _w;
	uint _tick;
}

class GUIStaticText : GUIImage
{
	this(GUIElement p, string text, ubyte font = 0, Font f = null, short maxWidth = short.max)
	{
		f = f ? f : PE.fonts.base;

		auto arr = f.toLines(text, maxWidth, 1, font);
		assert(arr.length == 1);

		auto m = PEobjs.makeHolder(f.render(arr[0], font));

		size = m.size;
		color = colorBlack;

		super(p, 0, 0, m);
	}
}
