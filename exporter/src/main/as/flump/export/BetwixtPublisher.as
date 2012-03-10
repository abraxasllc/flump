//
// Flump - Copyright 2012 Three Rings Design

package flump.export {

import com.threerings.util.Log;
import com.threerings.util.Map;
import com.threerings.util.Maps;
import com.threerings.util.XmlUtil;

import flash.filesystem.File;
import flash.filesystem.FileMode;
import flash.filesystem.FileStream;
import flash.utils.ByteArray;

import flump.bytesToXML;
import flump.xfl.XflLibrary;
import flump.xfl.XflMovie;
import flump.xfl.XflTexture;

public class BetwixtPublisher
{
    public static function modified (lib :XflLibrary, metadata :File) :Boolean
    {
        if (!metadata.exists) return true;

        var stream :FileStream = new FileStream();
        stream.open(metadata, FileMode.READ);
        var bytes :ByteArray = new ByteArray();
        stream.readBytes(bytes);

        var md5 :String = null;
        switch (Files.getExtension(metadata)) {
        case "xml":
            var xml :XML = bytesToXML(bytes);
            md5 = xml.@md5;
            break;

        case "json":
            var json :Object = JSON.parse(bytes.readUTFBytes(bytes.length));
            md5 = json.md5;
            break;
        }

        return md5 != lib.md5;
    }

    public static function publish (lib :XflLibrary, source :File, exportDir :File) :void {
        var packers :Array = [
            new Packer(DeviceType.IPHONE_RETINA, lib),
            new Packer(DeviceType.IPHONE, lib)
        ];

        const destDir :File = exportDir.resolvePath(lib.location);
        destDir.createDirectory();

        for each (var packer :Packer in packers) {
            for each (var atlas :Atlas in packer.atlases) {
                atlas.publish(exportDir);
            }
        }

        publishMetadata(lib, packers, destDir.resolvePath("resources.xml"));
        publishMetadata(lib, packers, destDir.resolvePath("resources.json"));
    }

    protected static function publishMetadata (lib :XflLibrary, packers :Array, dest :File) :void {
        var out :FileStream = new FileStream();
        out.open(dest, FileMode.WRITE);

        switch (Files.getExtension(dest)) {
        case "xml":
            var xml :XML = <resources md5={lib.md5}/>;
            for each (var movie :XflMovie in lib.movies) {
                xml.appendChild(movie.toXML());
            }
            var groupsXml :XML = <textureGroups/>;
            xml.appendChild(groupsXml);
            for each (var packer :Packer in packers) {
                var groupXml :XML = <textureGroup target={packer.targetDevice}/>;
                groupsXml.appendChild(groupXml);
                for each (var atlas :Atlas in packer.atlases) {
                    groupXml.appendChild(atlas.toXML());
                }
            }
            out.writeUTFBytes(xml.toString());
            break;

        case "json":
            var json :Object = {
                md5: lib.md5,
                movies: lib.movies,
                atlases: packers[0].atlases
            };
            var pretty :Boolean = false;
            out.writeUTFBytes(JSON.stringify(json, null, pretty ? "  " : null));
            break;
        }

        out.close();
    }

    private static const log :Log = Log.getLog(BetwixtPublisher);
}
}
