// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2012 Noise Developers (http://launchpad.net/noise)
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 *
 * Authored by: Scott Ringwelski <sgringwe@mtu.edu>
 *              Victor Eduardo <victoreduardm@gmail.com>
 */

// TODO: DEPRECATE
public enum Noise.MediaType {
    UNSPECIFIED,
    SONG,
    PODCAST,
    AUDIOBOOK,
    STATION
}

public class Noise.Media : Object {
    /// Used for unknown titles, artists, or album names.
    private static string UNKNOWN = _("Unknown");

    public int rowid { get; set; }
    public MediaType mediatype { get; set; default = MediaType.SONG; }

    private string _uri = "";
    public string uri {
        get { return _uri; }
        set {
            display_filename_updated = false;
            _uri = value;
        }
    }


    public uint64 file_size { get; set; default = 0; }
    public bool file_exists { get { return this.file.query_exists (); } }

    public File file {
        owned get { return File.new_for_uri (uri); }
        set { uri = value.get_uri (); }
    }

    public bool isPreview { get; set; default = false; }
    public bool isTemporary { get; set; default = false; }
    
    // TODO: evaluate if there's real need for these fields
    public bool location_unknown { get; set; default = false; }
    public bool has_embedded { get; set; default = false; }

    // XXX: these don't really belong here. It seems they only help to
    //      ease client-side stuff, and will be removed in the future
    public Gdk.Pixbuf? unique_status_image;
    public bool showIndicator { get; set; default = false; }
    public int pulseProgress { get; set; default = 0; }

    /**
     * Metadata Fields
     */
    public string title { get; set; default = ""; }
    public uint track { get; set; default = 0; }
    public uint track_count { get; set; default = 0; }
    public string composer { get; set; default = ""; }
    public string artist { get; set; default = ""; }
    public string album_artist { get; set; default = ""; }
    public string album { get; set; default = ""; }
    public uint album_number { get; set; default = 1; }
    public uint album_count { get; set; default = 1; }
    public string grouping { get; set; default = ""; }
    public string genre { get; set; default = ""; }
    public string comment { get; set; default = ""; }
    public string lyrics { get; set; default = ""; }
    public uint year { get; set; default = 0; }
    public uint bitrate { get; set; default = 0; }
    public uint bpm { get; set; default = 0; }
    public uint samplerate { get; set; default = 0; }
    public uint length { get; set; default = 0; } // duration in miliseconds

    private uint _rating;
    public uint rating {
        get { return _rating; }
        set { _rating = value.clamp (0, 5); }
    }

    /**
     * Internal stats
     */
    public uint play_count { get; set; default = 0; }
    public uint skip_count { get; set; default = 0; }
    public uint date_added { get; set; default = 0; }
    public uint last_played { get; set; default = 0; }
    public uint last_modified { get; set; default = 0; }

    public int resume_pos { get; set; default = 0; }

    private bool display_filename_updated = false;
    private string? cached_display_filename;
    private Cancellable query_filename_cancellable;

    /**
     * This call is still not fully synchronous because it's only used to get the display
     * filename without blocking from the list's cell-data functions. As their nature is
     * to check for that before every redraw, the value is updated as needed.
     */
    public inline string get_display_filename () {
        if (display_filename_updated && cached_display_filename != null)
            return cached_display_filename;

        if (query_filename_cancellable != null)
            query_filename_cancellable.cancel ();

        var cancellable = new Cancellable ();
        query_filename_cancellable = cancellable;

        FileUtils.query_name_async.begin (file, cancellable, (obj, res) => {
            if (!cancellable.is_cancelled ())
                cached_display_filename = FileUtils.query_name_async.end (res);
            display_filename_updated = true;
        });

        return UNKNOWN;
    }

    public inline string get_display_title () {
        string title = this.title;
        return is_valid_string_field (title) ? title : get_display_filename ();
    }

    public inline string get_display_composer () {
        return get_simple_display_text (composer);
    }

    public inline string get_display_artist () {
        return get_simple_display_text (artist);
    }

    public inline string get_display_album_artist () {
        string album_artist = this.album_artist;
        return is_valid_string_field (album_artist) ? album_artist : get_display_artist ();
    }

    public inline string get_display_album () {
        return get_simple_display_text (album);
    }

    public inline string get_display_genre () {
        return get_simple_display_text (genre);
    }

    public static inline bool is_valid_string_field (string text) {
        return !String.is_empty (text, true);
    }

    /**
     * It's called simple because it simply checks if the string is empty,
     * and returns UNKNOWN if it is.
     */
    private static inline string get_simple_display_text (string text) {
        return is_valid_string_field (text) ? text : UNKNOWN;
    }


    public Media (string uri) {
        this.uri = uri;
    }

    public Media.from_file (File file) {
        this.file = file;
    }

    public Media copy () {
        Media rv = new Media (uri);

        rv.mediatype = mediatype;
        rv.file_size = file_size;
        rv.track = track;
        rv.track_count = track_count;
        rv.album_number = album_number;
        rv.album_count = album_count;
        rv.title = title;
        rv.artist = artist;
        rv.composer = composer;
        rv.album_artist = album_artist;
        rv.album = album;
        rv.genre = genre;
        rv.grouping = grouping;
        rv.comment = comment;
        rv.year = year;
        rv.bitrate = bitrate;
        rv.length = length;
        rv.samplerate = samplerate;
        rv.bpm = bpm;
        rv.rating = rating;
        rv.play_count = play_count;
        rv.skip_count = skip_count;
        rv.date_added = date_added;
        rv.last_played = last_played;
        rv.lyrics = lyrics; 
        rv.isPreview = isPreview;
        rv.isTemporary = isTemporary;
        rv.last_modified = last_modified;
        rv.pulseProgress = pulseProgress;
        rv.showIndicator = showIndicator;
        rv.unique_status_image = unique_status_image;
        rv.location_unknown = location_unknown;

        return rv;
    }
}
