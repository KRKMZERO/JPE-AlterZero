package;

#if desktop
import Discord.DiscordClient;
#end
import editors.ChartingState;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.system.FlxSound;
import WeekData;

using StringTools;

class FreeplayState extends MusicBeatState
{
    // ===== カテゴリ関連 =====
    public static var categories:Array<String> = [];
    public static var curCategoryIndex:Int = 0;

    var songs:Array<SongMetadata> = [];
    private static var curSelected:Int = 0;
    var curDifficulty:Int = 0;

    var grpSongs:FlxTypedGroup<Alphabet>;
    var iconArray:Array<HealthIcon> = [];

    var bg:FlxSprite;
    var intendedColor:Int;
    var colorTween:FlxTween;

    var scoreText:FlxText;
    var diffText:FlxText;
    var categoryText:FlxText;

    override function create()
    {
        persistentUpdate = true;
        PlayState.isStoryMode = false;

        WeekData.reloadWeekFiles(false);

        // ===== カテゴリ一覧を自動生成 =====
        categories = [];
        for (week in WeekData.weeksLoaded)
        {
            var cat = week.category != null ? week.category : "freeplay";
            if (!categories.contains(cat))
                categories.push(cat);
        }
        categories.sort(StringTools.compare);

        if (curCategoryIndex >= categories.length)
            curCategoryIndex = 0;

        var currentCategory = categories[curCategoryIndex];

        #if desktop
        DiscordClient.changePresence("Freeplay", currentCategory);
        #end

        // ===== 曲収集 =====
        for (i in 0...WeekData.weeksList.length)
        {
            var weekName = WeekData.weeksList[i];
            var leWeek = WeekData.weeksLoaded.get(weekName);

            if (weekIsLocked(weekName))
                continue;

            var cat = leWeek.category != null ? leWeek.category : "freeplay";
            if (cat != currentCategory)
                continue;

            WeekData.setDirectoryFromWeek(leWeek);

            for (song in leWeek.songs)
            {
                var colors:Array<Int> = song[2];
                if (colors == null || colors.length < 3)
                    colors = [146, 113, 253];

                addSong(
                    song[0],
                    i,
                    song[1],
                    FlxColor.fromRGB(colors[0], colors[1], colors[2])
                );
            }
        }

        WeekData.setDirectoryFromWeek();

        // ===== 背景 =====
        bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
        bg.antialiasing = ClientPrefs.globalAntialiasing;
        add(bg);
        bg.screenCenter();

        // ===== カテゴリ表示 =====
        categoryText = new FlxText(20, 20, 0,
            "Category: " + currentCategory.toUpperCase(), 24);
        categoryText.setFormat(Paths.font("GameF.ttf"), 24, FlxColor.WHITE);
        add(categoryText);

        // ===== 曲リスト =====
        grpSongs = new FlxTypedGroup<Alphabet>();
        add(grpSongs);

        for (i in 0...songs.length)
        {
            var songText = new Alphabet(90, 320, songs[i].songName, true, 42);
            songText.isMenuItem = true;
            songText.targetY = i - curSelected;
            grpSongs.add(songText);

            Paths.currentModDirectory = songs[i].folder;
            var icon = new HealthIcon(songs[i].songCharacter);
            icon.sprTracker = songText;
            iconArray.push(icon);
            add(icon);
        }

        if (songs.length > 0)
        {
            bg.color = songs[0].color;
            intendedColor = bg.color;
        }

        scoreText = new FlxText(0, 0, 0, "", 24);
        add(scoreText);

        changeSelection();
        super.create();
    }

    override function update(elapsed:Float)
    {
        // ===== Tabで次のカテゴリ =====
        if (FlxG.keys.justPressed.TAB)
        {
            curCategoryIndex++;
            if (curCategoryIndex >= categories.length)
                curCategoryIndex = 0;

            FlxG.sound.play(Paths.sound('scrollMenu'));
            MusicBeatState.switchState(new FreeplayState());
            return;
        }

        if (controls.UI_UP_P)
            changeSelection(-1);
        if (controls.UI_DOWN_P)
            changeSelection(1);

        if (controls.BACK)
        {
            MusicBeatState.switchState(new MainMenuState());
        }

        super.update(elapsed);
    }

    function addSong(song:String, week:Int, char:String, color:Int)
    {
        songs.push(new SongMetadata(song, week, char, color));
    }

    function changeSelection(change:Int = 0)
    {
        if (songs.length == 0)
            return;

        curSelected += change;

        if (curSelected < 0)
            curSelected = songs.length - 1;
        if (curSelected >= songs.length)
            curSelected = 0;

        for (i in 0...grpSongs.length)
        {
            var item = grpSongs.members[i];
            item.targetY = i - curSelected;
            item.alpha = (item.targetY == 0) ? 1 : 0.6;
        }

        bg.color = songs[curSelected].color;
    }

    function weekIsLocked(name:String):Bool
    {
        var leWeek = WeekData.weeksLoaded.get(name);
        return (!leWeek.startUnlocked
            && leWeek.weekBefore.length > 0
            && (!StoryMenuState.weekCompleted.exists(leWeek.weekBefore)
            || !StoryMenuState.weekCompleted.get(leWeek.weekBefore)));
    }
}

class SongMetadata
{
    public var songName:String;
    public var week:Int;
    public var songCharacter:String;
    public var color:Int;
    public var folder:String;

    public function new(song:String, week:Int, char:String, color:Int)
    {
        this.songName = song;
        this.week = week;
        this.songCharacter = char;
        this.color = color;
        this.folder = Paths.currentModDirectory;
        if (this.folder == null) this.folder = '';
    }
}
