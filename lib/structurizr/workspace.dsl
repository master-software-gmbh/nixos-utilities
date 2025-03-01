workspace "Name" {
    !identifiers hierarchical
    !adrs adrs
    !docs docs

    model {
        u = person "User"
        ss = softwareSystem "Software System" {
            wa = container "Web Application"
            db = container "Database Schema" {
                tags "Database"
            }
        }

        u -> ss.wa "Uses"
        ss.wa -> ss.db "Reads from and writes to"
    }

    views {
        systemContext ss "Global" {
            include *
            autolayout lr
        }

        container ss "System" {
            include *
            autolayout lr
        }
    }
}
