$(document).ready(function() {
    $('body').hide();

    var btn = $(".PlayButton");
    var PlayButton = $("#buttonOne");
    var directPlay = $('#directPlay');
    var currentSongLabel = '';
    var buttonTwo = $('#buttonTwo');
    var buttonThree = $('#buttonThree');
    var buttonFour = $('#buttonFour');
    var buttonFive = $('#buttonFive');
    var addToPlaylist = $('#addToPlaylist');
    var HighestPlayListId = 0;
    var isDropDownOpen = false;
    var perc = 0;

    function nuiPost(name, data) {
        fetch(`https://${GetParentResourceName()}/${name}`, {
            method: 'POST',
            body: JSON.stringify(data || {})
        });
    }

    btn.click(function() {
        nuiPost('togglePlaystate', {});
        btn.toggleClass("paused");
        PlayButton.toggleClass("paused2");
        return false;
    });

    PlayButton.click(function() {
        nuiPost('togglePlaystate', {});
        btn.toggleClass("paused");
        PlayButton.toggleClass("paused2");
        return false;
    });

    directPlay.click(function() {
        nuiPost('playNewSong', {
            link: $('#linkInput').val()
        });
        return;
    });

    buttonTwo.click(function() {
        nuiPost('rewind', {});
        $('#timeLineInside').width($('#timeLineInside').width() - (perc * 10));
        return;
    });

    buttonThree.click(function() {
        nuiPost('forward', {});
        $('#timeLineInside').width($('#timeLineInside').width() + (perc * 10));
        return;
    });

    buttonFour.click(function() {
        nuiPost('down', {});
        return;
    });

    buttonFive.click(function() {
        nuiPost('up', {});
        return;
    });

    var AddPlaylist = $('#PlayListAddButton');
    AddPlaylist.click(function() {
        if ($('#CreatePlaylistName').val() != '') {
            var newHtml = $('#playlists').html();
            newHtml += `
            <div class="playlist" data-id="${HighestPlayListId}">
                <button id="playlist${HighestPlayListId}" class="playlistButton">${$('#CreatePlaylistName').val()}<i class="fas fa-trash-alt deletePlaylist"></i></button>
                <div id="songSpace${HighestPlayListId}" class="songs" data-id="${HighestPlayListId}" data-displayed="0"></div>
            </div>`;
            $('#playlists').html(newHtml);

            nuiPost('addPlayList', {
                id: HighestPlayListId,
                name: $('#CreatePlaylistName').val()
            });

            var addHtml = $('#addPlaylist').html();
            addHtml += `<p class="addPlaylistButton" data-id="${HighestPlayListId}">${$('#CreatePlaylistName').val()}</p>`;
            $('#addPlaylist').html(addHtml);

            HighestPlayListId = HighestPlayListId + 1;
            $('#CreatePlaylistName').val('');
        }
        return;
    });

    addToPlaylist.click(function() {
        var addPlaylist = $('#addPlaylist');
        if (isDropDownOpen) {
            isDropDownOpen = false;
            addPlaylist.animate({height: '0', width: '0'});
            setTimeout(function() {
                addPlaylist.css('display', 'none');
            }, 350);
        } else {
            isDropDownOpen = true;
            addPlaylist.css('display', 'block');
            addPlaylist.animate({height: '100%', width: '100%'});
        }
        return;
    });

    $(document).on('click', '.deleteSongs', function() {
        nuiPost('deleteSong', {
            id: $(this).parent().data('songid'),
            playlistId: $(this).parent().parent().data('id')
        });
        $(this).parent().remove();
    });

    $(document).on('click', '.deletePlaylist', function() {
        nuiPost('deletePlaylist', {
            id: $(this).parent().parent().data('id')
        });
        $(this).parent().parent().remove();
    });

    $(document).on('click', '.addPlaylistButton', function() {
        if ($('#linkInput').val()) {
            var i = $(this);
            $.getJSON('https://noembed.com/embed?url=', {format: 'json', url: $('#linkInput').val()}, function (data) {
                if (data.title) {
                    nuiPost('addSongToPlaylist', {
                        id: i.data('id'),
                        link: $('#linkInput').val()
                    });

                    var addPlaylist = $('#addPlaylist');
                    isDropDownOpen = false;
                    addPlaylist.animate({height: '0', width: '0'});
                    setTimeout(function() {
                        addPlaylist.css('display', 'none');
                    }, 350);
                    $('#linkInput').val('');
                } else {
                    nuiPost('noSongtitle', {});
                }
            });
        }
    });

    $(document).on('click', '.song', function() {
        nuiPost('playSongFromPlaylist', {
            id: $(this).data('songid'),
            link: $(this).data('link'),
            playlistId: $(this).parent().data('id')
        });
    });

    window.addEventListener('message', (event) => {
        const e = event.data;
        switch (e.type) {
            case "open":
                $('body').show();
                break;
            case "forceClose":
                $('body').hide();
                break;
            case "getPlaylists":
                HighestPlayListId = 0;
                $('#playlists').html('');
                $('#addPlaylist').html('');
                var newHtml = '';
                e.playlists.forEach((v) => {
                    var songsHtml = '';
                    e.songs.forEach((s) => {
                        if (s.playlist == v.id) {
                            songsHtml += `<p class="song" id="song${s.id}" data-songid="${s.id}" data-link="${s.link}">${s.label}<i class="fas fa-trash-alt deleteSongs"></i></p>`;
                        }
                    });
                    newHtml += `
                    <div class="playlist" data-id="${v.id}">
                        <button id="playlist${v.id}" class="playlistButton">${v.label}<i class="fas fa-trash-alt deletePlaylist"></i></button>
                        <div id="songSpace${v.id}" class="songs" data-id="${v.id}" data-displayed="0">
                            ${songsHtml}
                        </div>
                    </div>`;
                    HighestPlayListId = mathMax(HighestPlayListId, v.id + 1);
                });
                $('#playlists').html(newHtml);

                var addHtml = '';
                e.playlists.forEach((v) => {
                    addHtml += `<p class="addPlaylistButton" data-id="${v.id}">${v.label}</p>`;
                });
                $('#addPlaylist').html(addHtml);
                break;
            case "updateSeconds":
                perc = parseInt($('#timeLineInside').css('max-width')) / e.maxDuration;
                $('#timeLineInside').width($('#timeLineInside').width() + perc);
                updateTimeLabels(e.secs, e.maxDuration);
                break;
            case "updateSonginfos":
                $.getJSON('https://noembed.com/embed?url=', {format: 'json', url: e.link}, function (data) {
                    currentSongLabel = data.title || 'Unknown';
                    insertSonghistory(e.link, currentSongLabel);
                    $('#currentSong').text(currentSongLabel);
                });
                $('#timeLineInside').width("3%");
                updateTimeLabels(0, e.maxDuration);
                break;
            default:
                break;
        }
    });

    function updateTimeLabels(secs, maxDuration) {
        // current time
        if (secs > 59) {
            var s = Math.round((secs / 60 - Math.floor(secs / 60)) * 60);
            var m = Math.floor(secs / 60);
            $('#currentTime').text(
                (m < 10 ? '0' + m : m) + ':' + (s < 10 ? '0' + s : s)
            );
        } else {
            $('#currentTime').text('00:' + (secs < 10 ? '0' + secs : secs));
        }

        // max time
        if (maxDuration > 59) {
            var s2 = Math.round((maxDuration / 60 - Math.floor(maxDuration / 60)) * 60);
            var m2 = Math.floor(maxDuration / 60);
            $('#maxTime').text(
                (m2 < 10 ? '0' + m2 : m2) + ':' + (s2 < 10 ? '0' + s2 : s2)
            );
        } else {
            $('#maxTime').text('00:' + (maxDuration < 10 ? '0' + maxDuration : maxDuration));
        }
    }

    document.addEventListener("keydown", function(event) {
        if (event.keyCode === 27) {
            $('body').hide();
            nuiPost('close', {});
        }
    });

    var songs;
    var PlaylistIsVisible = false;
    var currentPlaylistId = 0;

    $(document).on('click', '.playlist', function() {
        songs = $(this).find('.songs');
        var bla = songs.find('p');
        if (songs.data('id') == 'songhistory' && PlaylistIsVisible == false) {
            if (songs.data("displayed") == 0) {
                songs.css('display', 'block');
                songs.css('margin-bottom', '1vh');
                currentPlaylistId = songs.data('id');
                songs.animate({height: '100%'});
                setTimeout(function() {
                    songs.data("displayed", "1");
                    PlaylistIsVisible = true;
                }, 500);
            }
        } else if ($(this, '.songs').data('id') == songs.data('id') && PlaylistIsVisible == false && bla.html()) {
            if (songs.data("displayed") == 0) {
                songs.css('display', 'block');
                songs.css('margin-bottom', '1vh');
                currentPlaylistId = songs.data('id');
                songs.animate({height: '100%'});
                setTimeout(function() {
                    songs.data("displayed", "1");
                    PlaylistIsVisible = true;
                }, 500);
            }
        }
    });

    $(window).click(function(e) {
        var target = document.getElementById(e.target.id);
        if (document.getElementById('playlist' + currentPlaylistId) == target && songs && PlaylistIsVisible) {
            songs.animate({height: '0'});
            songs.data("displayed", "0");
            songs.css('margin-bottom', '0');
            PlaylistIsVisible = false;
        }
    });

    var outside = document.getElementById('timeLineOutside');
    var inside = document.getElementById('timeLineInside');

    outside.addEventListener('click', function(e) {
        inside.style.width = e.offsetX + "px";
        var pct = Math.floor((e.offsetX / outside.offsetWidth) * 100);
        // could send pct to Lua if you want seeking
    }, false);

    function insertSonghistory(link, label) {
        var elem = $('#songSpacesonghistory');
        var html = elem.html();
        if (html) {
            elem.html(html + '<p id="songsonghistory" data-link="' + link + '">' + label + '<i class="fas fa-trash-alt"></i></p>');
        } else {
            elem.html('<p id="songsonghistory" data-link="' + link + '">' + label + '<i class="fas fa-trash-alt"></i></p>');
        }
    }

    function mathMax(a, b) {
        return a > b ? a : b;
    }
});



