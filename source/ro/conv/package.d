module ro.conv;
import std.file, std.format, std.path, std.conv, std.range, std.getopt,
	std.process, std.digest.md, core.memory, perfontain, perfontain.misc, ro.conv.asp,
	ro.conv.map, ro.conv.gui, ro.conv.all, ro.conv.item, ro.conv.effect,
	rocl.rofs, rocl.game, ro.paths;

package:

abstract class Converter(T)
{
	this(in ubyte[16] hash)
	{
		_saveHash = hash.toHexString;
	}

	T convert()
	{
		assert(_saveHash);
		auto p = format(`converted/%s`, _saveHash);

		try
		{
			return PEfs.read!T(p);
		}
		catch (Exception ex)
		{
			logger.warning(ex.msg);
		}

		auto res = process;
		ROfs.put(p, res.serializeMem);
		return res;
	}

	auto imageOf(RoPath s)
	{
		if (auto p = s in _images)
		{
			return *p;
		}

		auto im = new Image(ROfs.get(s));
		im.clean;

		return _images[s] = im;
	}

protected:
	T process();

private:
	string _saveHash;
	Image[RoPath] _images;
}
