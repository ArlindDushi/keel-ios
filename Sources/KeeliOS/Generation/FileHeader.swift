import Foundation

enum FileHeader {
    /// The comment block every generated Swift file starts with.
    static func swift(fileName: String, targetName: String, author: String, organization: String, date: Date) -> String {
        let organization = copyrightHolder(organization)
        return """
        //
        //  \(fileName)
        //  \(targetName)
        //
        //  Created by \(author) on \(date.formatted(date: .numeric, time: .omitted)).
        //  Copyright © \(date.formatted(.dateTime.year())) \(organization). All rights reserved.
        //


        """
    }

    /// `IDETemplateMacros.plist`, so files created later in Xcode get the same header.
    static func templateMacrosPlist(organization: String) throws -> Data {
        let organization = copyrightHolder(organization)
        let header = """

        //  ___FILENAME___
        //  ___TARGETNAME___
        //
        //  Created by ___FULLUSERNAME___ on ___DATE___.
        //  Copyright © ___YEAR___ \(organization). All rights reserved.
        //
        """
        return try PropertyListSerialization.data(fromPropertyList: ["FILEHEADER": header], format: .xml, options: 0)
    }
}

private extension FileHeader {
    /// "Example Inc." → "Example Inc", so the header doesn't end up with "Inc.. All rights reserved."
    static func copyrightHolder(_ organization: String) -> String {
        organization.hasSuffix(".") ? String(organization.dropLast()) : organization
    }
}
