/**
 * Result from the thumbnail transformation.
 *
 * @author Alibaba CLoud
 */
class ThumbnailTransformationResult {

    /**
     * @param {Array.<bucket: String, key: String>} savedThumbnails
     * @param {Array.<{bucket: String, key: String, error: String}>} problematicImages
     */
    constructor(savedThumbnails, problematicImages) {
        /** @type {Array.<{bucket: String, key: String}>} */
        this.savedThumbnails = savedThumbnails;

        /** @type {Array.<{bucket: String, key: String, error: String}>} */
        this.problematicImages = problematicImages;
    }
}

module.exports = ThumbnailTransformationResult;