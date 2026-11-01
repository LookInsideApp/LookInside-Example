import WatchKit

/// The playlists, one table row each.
final class PlaylistsInterfaceController: WKInterfaceController {
    @IBOutlet private var playlistTable: WKInterfaceTable!

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        setTitle("Playlists")
        playlistTable.setNumberOfRows(Playlist.samples.count, withRowType: "PlaylistRow")
        for (index, playlist) in Playlist.samples.enumerated() {
            guard let row = playlistTable.rowController(at: index) as? PlaylistRowController else { continue }
            row.iconImage.setImage(UIImage(systemName: playlist.symbolName))
            row.iconImage.setTintColor(playlist.tint.uiColor)
            row.nameLabel.setText(playlist.name)
            row.detailLabel.setText("\(playlist.trackCount) tracks · \(playlist.durationInMinutes) min")
        }
    }
}

final class PlaylistRowController: NSObject {
    @IBOutlet var iconImage: WKInterfaceImage!
    @IBOutlet var nameLabel: WKInterfaceLabel!
    @IBOutlet var detailLabel: WKInterfaceLabel!
}
